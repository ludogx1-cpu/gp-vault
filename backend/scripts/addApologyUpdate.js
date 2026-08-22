// Script to add apology
require('dotenv').config({ path: '../.env' });
const { admin } = require('../src/services/firebaseService');

const db = admin.firestore();

async function addApology() {
  try {
    const title = "Service Restored: Recent Login Issues";
    const message = "We sincerely apologize to users who were unable to access their accounts recently. We have been making significant backend improvements and were unfortunately unaware of the login issue until very recently. The problem has now been fully resolved. Thank you for your patience!";
    
    await db.collection('updates').add({
      title: title,
      message: message,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log("Apology update added successfully.");
  } catch (error) {
    console.error("Error adding update:", error);
  } finally {
    process.exit(0);
  }
}

addApology();
