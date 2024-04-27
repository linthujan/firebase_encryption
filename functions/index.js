/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// const { onRequest } = require("firebase-functions/v2/https");
// const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });


// The Cloud Functions for Firebase SDK to create Cloud Functions and triggers.
const { logger } = require("firebase-functions");
const { onRequest, onCall } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");

// The Firebase Admin SDK to access Firestore.
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const NodeRSA = require("node-rsa");

initializeApp();

// Take the text parameter passed to this HTTP endpoint and insert it into
// Firestore under the path /messages/:documentId/original
exports.adduser = onRequest(async (req, res) => {
    const { username, symmetricKeyHash } = req.body.data;
    console.log(username);
    const writeResult = await getFirestore().collection("users").add({ username, symmetricKeyHash });
    res.json({ result: writeResult.id, });
});

exports.savecardnumber = onRequest(async (req, res) => {
    const { cardNumber, userId } = req.body.data;
    console.log("cardNumber :", cardNumber);
    const writeResult = await getFirestore().collection("users").doc(userId).collection("cards").add({
        cardNumber,
    });

    res.json({ result: writeResult.id });
});

exports.loadcardnumbers = onRequest(async (req, res) => {
    const { userId } = req.body.data;
    console.log(userId);
    const publicKeyString = (await getFirestore().collection("keys").doc("1").get()).get("publicKey");
    const privateKeyString = (await getFirestore().collection("keys").doc("1").get()).get("privateKey");
    const symmetricKeyHash = (await getFirestore().collection("users").doc(userId).get()).get("symmetricKeyHash");
    // console.log({ publicKeyString, privateKeyString, symmetricKeyHash });
    const privateKey = new NodeRSA(privateKeyString);

    const cards = await getFirestore().collection("users").doc(userId).collection("cards").get();

    let cardsArray = [];
    cards.forEach(card => {
        const decryptedData = privateKey.decrypt(card.get("cardNumber"), 'utf8');
        cardsArray.push(decryptedData);
    });
    const symmetricKey = privateKey.decrypt(symmetricKeyHash, 'utf8');

    console.log(cardsArray);
    res.json({ result: { cardsArray, symmetricKey } });
});

exports.getpublickey = onRequest(async (req, res) => {
    const keys = await getFirestore().collection("keys").doc("1").get();

    // console.log('keys', keys.get("publicKey"));
    res.json({ result: keys.get("publicKey") });
});

exports.setpublickey = onRequest(async (req, res) => {
    const key = new NodeRSA({ b: 1024 });

    console.log(`Key-Type : ${key.isPublic() ? "Public Key" : "Private Key"}`);
    console.log(`Key-Type : ${key.isPrivate() ? "Private Key" : "Public Key"}`);

    const publicKey = key.exportKey('public');
    const privateKey = key.exportKey('private');

    console.log(publicKey);
    console.log(privateKey);

    await getFirestore().collection("keys").doc("1").delete();
    const keys = await getFirestore().collection("keys").doc("1").create({ publicKey, privateKey });

    res.json({ result: keys });
});

// Listens for new messages added to /messages/:documentId/original
// and saves an uppercased version of the message
// to /messages/:documentId/uppercase
// exports.makeuppercase = onDocumentCreated("/messages/{documentId}", (event) => {
//     // Grab the current value of what was written to Firestore.
//     const original = event.data.data().original;

//     // Access the parameter `{ documentId }` with `event.params`
//     logger.log("Uppercasing", event.params.documentId, original);

//     const uppercase = original.toUpperCase();

//     // You must return a Promise when performing
//     // asynchronous tasks inside a function
//     // such as writing to Firestore.
//     // Setting an 'uppercase' field in Firestore document returns a Promise.
//     return event.data.ref.set({ uppercase }, { merge: true });
// });