require('dotenv').config();
const fs = require('fs');
const { admin } = require('./src/services/firebaseService');

async function exportEmails() {
  console.log('Fetching users from Firebase Auth...');
  const emails = [];
  let nextPageToken;

  try {
    do {
      // Fetch users in batches of 1000
      const listUsersResult = await admin.auth().listUsers(1000, nextPageToken);
      listUsersResult.users.forEach((userRecord) => {
        if (userRecord.email) {
          emails.push(userRecord.email);
        }
      });
      nextPageToken = listUsersResult.pageToken;
    } while (nextPageToken);

    console.log(`Found ${emails.length} emails. Writing to subscribers.csv...`);

    // Create a basic CSV format with an "email" header which Substack requires
    const csvContent = "email\n" + emails.join("\n");
    
    fs.writeFileSync('subscribers.csv', csvContent);
    
    console.log('Successfully saved to subscribers.csv!');
    console.log('You can now upload this file directly to Substack.');
    process.exit(0);

  } catch (error) {
    console.error('Error fetching users:', error);
    process.exit(1);
  }
}

exportEmails();
