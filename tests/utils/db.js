const fs = require('fs');
const zlib = require('zlib');


const clearDatabase = async () => {
    const knex = require('knex')({
        client: 'mysql',
        connection: {
          host: process.env.DB_HOST || 'localhost',
          port: process.env.DB_PORT || '8082',
          user: 'judgebooth',
          password: 'judgebooth',
          database: 'judgebooth',
          multipleStatements: true
        }
    });

    const sql = fs.readFileSync(`${__dirname}/../judgebooth.only-data-test.sql`).toString();
    await knex.raw(sql);
    await knex.destroy();
}


module.exports = {
    clearDatabase,
}