const fs = require('fs');
const path = require('path');

describe('Data Connect operation auth', () => {
  const mutations = fs.readFileSync(
    path.join(__dirname, '../../dataconnect/example/mutations.gql'),
    'utf8'
  );

  it.each(['UpdateUserBalances', 'UpdatePetStats', 'MigrateUser'])(
    'keeps sensitive %s mutation server-only',
    (operationName) => {
      const operationPattern = new RegExp(
        `mutation\\s+${operationName}[\\s\\S]*?\\)\\s+@auth\\(level:\\s+NO_ACCESS\\)`,
        'm'
      );

      expect(mutations).toMatch(operationPattern);
    }
  );
});
