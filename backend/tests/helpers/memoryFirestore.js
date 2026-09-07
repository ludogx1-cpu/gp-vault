function memoryFirestore() {
  const rows = new Map();
  let sequence = 0;
  let queue = Promise.resolve();
  const snapshot = ref => ({ id: ref.id, ref, exists: rows.has(ref.path), data: () => ({ ...rows.get(ref.path) }) });
  const apply = (ref, updates, replace = false) => {
    const value = replace ? {} : { ...rows.get(ref.path) };
    for (const [key, entry] of Object.entries(updates)) {
      if (entry?.kind === 'delete') delete value[key];
      else if (entry?.kind === 'increment') value[key] = Number(value[key] || 0) + entry.operand;
      else value[key] = entry;
    }
    rows.set(ref.path, value);
  };
  const db = {
    rows,
    failCommit: false,
    collection(name) {
      const collection = {
        doc(id = `auto-${++sequence}`) {
          const ref = { id, path: `${name}/${id}` };
          ref.get = async () => snapshot(ref);
          ref.update = async updates => apply(ref, updates);
          ref.set = async updates => apply(ref, updates, true);
          ref.delete = async () => rows.delete(ref.path);
          return ref;
        },
        async add(data) { const ref = collection.doc(); await ref.set(data); return ref; },
        where(field, op, value) {
          const query = {
            limit: () => query,
            async get() {
              const docs = [...rows.keys()].filter(path => path.startsWith(`${name}/`) && rows.get(path)[field] === value)
                .map(path => snapshot(collection.doc(path.slice(name.length + 1))));
              return { docs, empty: docs.length === 0, size: docs.length };
            },
          };
          return query;
        },
      };
      return collection;
    },
    runTransaction(callback) {
      const task = queue.then(async () => {
        const writes = [];
        const result = await callback({
          get: async ref => {
            if (writes.length) throw new Error('Read after write');
            return snapshot(ref);
          },
          update: (ref, data) => writes.push(() => apply(ref, data)),
          set: (ref, data) => writes.push(() => apply(ref, data, true)),
        });
        if (db.failCommit) throw new Error('Simulated interrupted commit');
        writes.forEach(write => write());
        return result;
      });
      queue = task.catch(() => {});
      return task;
    },
  };
  return db;
}
const FieldValue = {
  increment: operand => ({ kind: 'increment', operand }),
  delete: () => ({ kind: 'delete' }),
  serverTimestamp: () => ({ toDate: () => new Date() }),
};
module.exports = { memoryFirestore, FieldValue };
