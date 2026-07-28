const { admin } = require('./src/services/firebaseService');

async function run() {
  const collections = await admin.firestore().listCollections();
  collections.forEach(collection => {
    console.log(collection.id);
  });
  process.exit(0);
}
run();
