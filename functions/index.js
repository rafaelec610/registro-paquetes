/**************************************************
 * IMPORTS (Cloud Functions v2)
 **************************************************/
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");

/**************************************************
 * INIT
 **************************************************/
admin.initializeApp();
const db = admin.firestore();

/**************************************************
 * 1️⃣ FUNCIÓN PROGRAMADA — VERIFICAR PAQUETES
 **************************************************/
exports.verificarPaquetes = onSchedule(
  {
    schedule: "every 24 hours",
    timeZone: "America/Bogota",
  },
  async () => {
    console.log("⏰ Verificando paquetes...");

    const paquetesSnap = await db.collection("paquetes").get();
    const usuariosSnap = await db.collection("usuarios").get();

    if (paquetesSnap.empty || usuariosSnap.empty) {
      console.log("⚠ No hay paquetes o usuarios");
      return;
    }

    const tokens = {
      admin: [],
      cajero: [],
      repartidor: [],
    };

    usuariosSnap.forEach((doc) => {
      const u = doc.data();
      if (u.fcmToken && tokens[u.rol]) {
        tokens[u.rol].push(u.fcmToken);
      }
    });

    for (const paqueteDoc of paquetesSnap.docs) {
      const p = paqueteDoc.data();
      let nuevoEstado = "verde";

      if (p.dias >= 5) nuevoEstado = "rojo";
      else if (p.dias >= 3) nuevoEstado = "amarillo";

      if (nuevoEstado === "amarillo" && !p.alertaAmarillaEnviada) {
        await enviarNotificacion(p, tokens, "amarillo");
        await paqueteDoc.ref.update({
          estado: "amarillo",
          alertaAmarillaEnviada: true,
        });
      }

      if (nuevoEstado === "rojo" && !p.alertaRojaEnviada) {
        await enviarNotificacion(p, tokens, "rojo");
        await paqueteDoc.ref.update({
          estado: "rojo",
          alertaRojaEnviada: true,
        });
      }
    }

    console.log("✅ Verificación finalizada");
  }
);

/**************************************************
 * 2️⃣ NOTIFICACIONES POR ROL
 **************************************************/
async function enviarNotificacion(paquete, tokens, nivel) {
  const titulo =
    nivel === "amarillo"
      ? "⚠ Paquete próximo a vencer"
      : "🚨 Paquete vencido";

  const cuerpo = `Código ${paquete.codigo} – ${paquete.dias} días`;

  await enviarFCM(tokens.admin, titulo, cuerpo);

  if (paquete.tipoEntrega === "oficina") {
    await enviarFCM(tokens.cajero, titulo, cuerpo);
  }

  if (paquete.tipoEntrega === "domicilio") {
    await enviarFCM(tokens.repartidor, titulo, cuerpo);
  }
}

/**************************************************
 * 3️⃣ ENVÍO FCM
 **************************************************/
async function enviarFCM(tokens, title, body) {
  if (!tokens || tokens.length === 0) return;

  await admin.messaging().sendEachForMulticast({
    notification: { title, body },
    tokens,
  });
}

/**************************************************
 * 4️⃣ ASIGNAR NÚMERO DE OFICINA (CALLABLE)
 **************************************************/
exports.asignarNumeroOficina = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Usuario no autenticado");
  }

  const { paqueteId } = request.data;

  const paqueteRef = db.collection("paquetes").doc(paqueteId);
  const configRef = db.collection("config").doc("oficina");

  return db.runTransaction(async (tx) => {
    const paqueteSnap = await tx.get(paqueteRef);

    if (!paqueteSnap.exists) {
      throw new HttpsError("not-found", "Paquete no existe");
    }

    const paquete = paqueteSnap.data();

    if (paquete.tipoEntrega !== "oficina") {
      throw new HttpsError("failed-precondition", "No es paquete de oficina");
    }

    if (paquete.numeroOficina) {
      return { numero: paquete.numeroOficina };
    }

    const configSnap = await tx.get(configRef);
    const ocupados = configSnap.exists
      ? configSnap.data().numerosOcupados || []
      : [];

    let numeroLibre = null;
    for (let i = 1; i <= 99; i++) {
      if (!ocupados.includes(i)) {
        numeroLibre = i;
        break;
      }
    }

    if (!numeroLibre) {
      throw new HttpsError("resource-exhausted", "No hay números disponibles");
    }

    tx.update(paqueteRef, { numeroOficina: numeroLibre });
    tx.set(
      configRef,
      { numerosOcupados: [...ocupados, numeroLibre] },
      { merge: true }
    );

    return { numero: numeroLibre };
  });
});

/**************************************************
 * 5️⃣ LIBERAR NÚMERO AL ELIMINAR PAQUETE
 **************************************************/
exports.liberarNumeroOficina = onDocumentDeleted(
  "paquetes/{paqueteId}",
  async (event) => {
    const data = event.data?.data();
    if (!data?.numeroOficina) return;

    const configRef = db.collection("config").doc("oficina");

    await db.runTransaction(async (tx) => {
      const configSnap = await tx.get(configRef);
      if (!configSnap.exists) return;

      const ocupados = configSnap.data().numerosOcupados || [];
      const nuevos = ocupados.filter(
        (n) => n !== data.numeroOficina
      );

      tx.update(configRef, { numerosOcupados: nuevos });
    });
  }
);

exports.actualizarMetricas = onDocumentWritten(
  "paquetes/{paqueteId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!after) return;

    const hoy = new Date().toISOString().split("T")[0];
    const ref = db.collection("metricas_diarias").doc(hoy);

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const data = snap.exists ? snap.data() : {
        fecha: admin.firestore.Timestamp.now(),
        entradas: 0,
        entregas: 0,
        devoluciones: 0,
        oficina: 0,
        domicilio: 0,
        verde: 0,
        amarillo: 0,
        rojo: 0,
      };

      // 📦 Entrada nueva
      if (!before && after) {
        data.entradas += 1;
        after.tipoEntrega === "oficina"
          ? data.oficina++
          : data.domicilio++;
      }

      // 🚚 Entregado
      if (before?.estado !== "entregado" && after.estado === "entregado") {
        data.entregas += 1;
      }

      // ↩️ Devuelto
      if (after.estado === "devuelto") {
        data.devoluciones += 1;
      }

      // 🔴🟡🟢 Estados
      data.verde = 0;
      data.amarillo = 0;
      data.rojo = 0;

      tx.set(ref, data, { merge: true });
    });
  }
);

exports.generarMetricasDiarias = onSchedule(
  { schedule: "59 23 * * *", timeZone: "America/Bogota" },
  async () => {
    const hoy = new Date().toISOString().substring(0, 10);
    const ref = db.collection("metricas_diarias").doc(hoy);

    const snapshot = await db.collection("paquetes").get();

    const total = {
      entradas: 0,
      entregas: 0,
      devoluciones: 0,
      oficina: 0,
      domicilio: 0,
      verde: 0,
      amarillo: 0,
      rojo: 0,
    };

    const porRol = {
      cajero: { entradas: 0, devoluciones: 0 },
      repartidor: { entregas: 0, devoluciones: 0 },
    };

    snapshot.forEach(doc => {
      const p = doc.data();

      // Entradas
      total.entradas++;
      p.tipoEntrega === "oficina"
        ? total.oficina++
        : total.domicilio++;

      // Estados
      if (p.estado === "verde") total.verde++;
      if (p.estado === "amarillo") total.amarillo++;
      if (p.estado === "rojo") total.rojo++;

      // Entregas / devoluciones
      if (p.estado === "entregado") total.entregas++;
      if (p.estado === "devuelto") total.devoluciones++;

      // Por rol
      if (p.rol === "cajero") {
        porRol.cajero.entradas++;
        if (p.estado === "devuelto") porRol.cajero.devoluciones++;
      }

      if (p.rol === "repartidor") {
        if (p.estado === "entregado") porRol.repartidor.entregas++;
        if (p.estado === "devuelto") porRol.repartidor.devoluciones++;
      }
    });

    await ref.set({
      fecha: hoy,
      total,
      porRol,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ Métricas generadas para ${hoy}`);
  }
);
exports.generarMetricasDiariasManual = functions
  .region('us-central1')
  .https.onRequest(async (req, res) => {
    try {
      const admin = require('firebase-admin');
      admin.initializeApp();
      const db = admin.firestore();

      const hoy = new Date().toISOString().split('T')[0];

      const paquetesSnap = await db.collection('paquetes').get();

      let metricas = {
        fecha: hoy,
        total_paquetes: 0,
        total_entregados: 0,
        total_pendientes: 0,
        por_rol: {
          cajero: { creados: 0, entregados: 0 },
          repartidor: { asignados: 0, entregados: 0 },
        },
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      };

      paquetesSnap.forEach(doc => {
        const p = doc.data();
        metricas.total_paquetes++;

        if (p.estado === 'entregado') {
          metricas.total_entregados++;
        } else {
          metricas.total_pendientes++;
        }

        if (p.creado_por === 'cajero') {
          metricas.por_rol.cajero.creados++;
          if (p.estado === 'entregado') {
            metricas.por_rol.cajero.entregados++;
          }
        }

        if (p.repartidor_id) {
          metricas.por_rol.repartidor.asignados++;
          if (p.estado === 'entregado') {
            metricas.por_rol.repartidor.entregados++;
          }
        }
      });

      await db.collection('metricas_diarias').doc(hoy).set(metricas);

      res.status(200).send({ ok: true, metricas });
    } catch (e) {
      res.status(500).send(e.toString());
    }
  });

exports.generarMetricasHoy = functions.https.onCall(async (data, context) => {
  if (!context.auth || context.auth.token.rol !== 'admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Solo admin'
    );
  }

  const hoy = new Date().toISOString().split('T')[0];
  const snapshot = await db
    .collection('paquetes')
    .where('fecha', '==', hoy)
    .get();

  let metricas = {
    fecha: hoy,
    total_paquetes: snapshot.size,
    cajero: { total: 0, por_usuario: {} },
    repartidor: { total: 0, por_usuario: {} },
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  };

  snapshot.forEach(doc => {
    const p = doc.data();
    const rol = p.rol;

    metricas[rol].total++;

    metricas[rol].por_usuario[p.usuarioId] =
      (metricas[rol].por_usuario[p.usuarioId] || 0) + 1;
  });

  await db.collection('metricas_diarias').doc(hoy).set(metricas);

  return { ok: true };
});



