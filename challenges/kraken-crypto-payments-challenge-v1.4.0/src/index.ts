import {
  Sequelize,
  Model,
  DataTypes,
  HasManyGetAssociationsMixin,
  HasManyHasAssociationMixin,
  Association,
  HasManyCountAssociationsMixin,
  Optional,
} from "sequelize";
import fs from "fs";
const DEFAULT_DATABASE_URL: string = "postgres://postgres:password@localhost:5432/postgres";

const DB_URL: string = process.env.DATABASE_URL as string || DEFAULT_DATABASE_URL;

const sequelize = new Sequelize(DB_URL);

interface CustomerAttributes {
  id: number | null;
  name: string;
  address: string;
}

interface CustomerCreationAttributes extends Optional<CustomerAttributes, "id"> { }

class Customer extends Model<CustomerAttributes, CustomerCreationAttributes>
  implements CustomerAttributes {
  public id!: number; // Note that the `null assertion` `!` is required in strict mode.
  public address!: string;
  public name!: string;

  // timestamps!
  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;

  // we have to declare them here purely virtually
  // these will not exist until `Model.init` was called.
  public getTransactions!: HasManyGetAssociationsMixin<Transaction>; // Note the null assertions!
  public hasTransaction!: HasManyHasAssociationMixin<Transaction, number>;
  public countTransactions!: HasManyCountAssociationsMixin;

  // You can also pre-declare possible inclusions, these will only be populated if you
  // actively include a relation.
  public readonly transactions?: Transaction[]; // Note this is optional since it's only populated when explicitly requested in code

  public static associations: {
    transaction: Association<Customer, Transaction>;
  };
}

interface TransactionAttributes {
  id?: number;
  involvesWatchonly: boolean;
  account: string;
  address: string;
  category: string;
  amount: number;
  label: string;
  confirmations: number;
  blockhash: string;
  blockindex: number;
  txid: string;
  vout: number;
  walletconflicts: Array<any>;
  time: number;
  timereceived: number;
  "bip125-replaceable": string;
  createdAt?: Date;
  updatedAt?: Date;
}

interface TransactionCreationAttributes extends Optional<TransactionAttributes, "id"> { }

class Transaction extends Model<TransactionAttributes, TransactionCreationAttributes>
  implements TransactionAttributes {
  public id!: number;
  public involvesWatchonly: boolean;
  public account: string;
  public address: string;
  public category: string;
  public amount: number;
  public label: string;
  public confirmations: number;
  public blockhash: string;
  public blockindex: number;
  public txid: string;
  public vout: number;
  public walletconflicts: Array<any>;
  public time: number;
  public timereceived: number;
  public "bip125-replaceable": string;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
}

Transaction.init(
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    involvesWatchonly: {
      type: DataTypes.BOOLEAN,
      allowNull: true
    },
    account: {
      type: DataTypes.STRING,
      allowNull: true
    },
    address: {
      type: DataTypes.STRING,
      allowNull: true
    },
    category: {
      type: DataTypes.STRING,
      allowNull: true
    },
    amount: {
      type: DataTypes.FLOAT,
      allowNull: true
    },
    label: {
      type: DataTypes.STRING,
      allowNull: true
    },
    confirmations: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    blockhash: {
      type: DataTypes.STRING,
      allowNull: true
    },
    blockindex: {
      type: DataTypes.BIGINT,
      allowNull: true
    },
    txid: {
      type: DataTypes.STRING,
      allowNull: true
    },
    vout: {
      type: DataTypes.BIGINT,
      allowNull: true
    },
    walletconflicts: {
      type: DataTypes.ARRAY(DataTypes.STRING),
      allowNull: true
    },
    time: {
      type: DataTypes.BIGINT,
      allowNull: true
    },
    timereceived: {
      type: DataTypes.BIGINT,
      allowNull: true
    },
    "bip125-replaceable": {
      type: DataTypes.STRING,
      allowNull: true
    }
  },
  {
    sequelize,
    tableName: "transactions",
  }
);

Customer.init(
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    name: {
      type: new DataTypes.STRING,
      allowNull: false,
    },
    address: {
      type: new DataTypes.STRING,
      allowNull: false,
      unique: true
    },
  },
  {
    tableName: "customers",
    sequelize, // passing the `sequelize` instance is required
  }
);

interface ReturnDataType {
  transactions: Array<TransactionAttributes>,
  customers: Array<CustomerAttributes>
}

/**
* Synchonously reads json file and parses to object
* @param {String} path
* @returns {Object}
*/
const parseJSON = (path: string): ReturnDataType => {
  let object: ReturnDataType;
  const absoultePath = `${__dirname}/${path}`;
  if (fs.existsSync(absoultePath)) {
    const buffer: Buffer = fs.readFileSync(absoultePath);
    try {
      object = JSON.parse(buffer.toString());
    } catch (e) {
      console.error("JSON.parse Error", e);
    }
  }
  return object;
}

const executeQuery = (queryString: string): Promise<[unknown[], unknown]> => {
  return sequelize.query(queryString, { logging: false });
}

const printKnownDeposit = async () => {
  const [knownDeposits]: [unknown[], unknown] = await executeQuery(
    `select transactions.address, customers.name, COUNT(transactions.address), SUM(transactions.amount)
    from transactions
    right join customers on transactions.address = customers.address
    where transactions.confirmations >= 6 and transactions.category in('receive','generate')
    group by transactions.address, customers.name;`
  );
  for (let index in knownDeposits) {
    console.log(`Deposited for ${knownDeposits[index]['name']}: count=${knownDeposits[index]['count']} sum=${knownDeposits[index]['sum']}`);
  }
}

const printUnknownDeposit = async () => {
  const [[unknownDeposit]]: [unknown[], unknown] = await executeQuery(
    `select COUNT(*), SUM(t.amount) from (select transactions.address, transactions.amount
    from transactions
    left join customers on transactions.address = customers.address
    where customers.address is null and 
    transactions.confirmations >= 6 and 
    transactions.category in('receive','generate')) as t;`
  );
  console.log(`Deposited without reference: count=${unknownDeposit['count']} sum=${unknownDeposit['sum']}`)
}

const printMinDeposit = async () => {
  const [[minDeposit]]: [unknown[], unknown] = await executeQuery(
    `select MIN(t.sum) from (select address,COUNT(address),SUM(amount) from transactions
    where confirmations >= 6 and category in('receive','generate')
    group by address) as t;`
  );
  console.log(`Smallest valid deposit: ${minDeposit['min']}`)
}

const printMaxDeposit = async () => {
  const [[maxDeposit]]: [unknown[], unknown] = await executeQuery(
    `select MAX(t.sum) from (select address,COUNT(address),SUM(amount) from transactions
    where confirmations >= 6 and category in('receive','generate')
    group by address) as t;`
  );
  console.log(`Largest valid deposit: ${maxDeposit['max']}`)
}


async function processTransactions() {
  await sequelize.sync({ force: true, logging: false });
  const knownCustomers = parseJSON("seeds/customers.json").customers;
  const transactions = parseJSON("seeds/transactions-1.json").transactions.concat(parseJSON("seeds/transactions-2.json").transactions)
  await Customer.bulkCreate(knownCustomers, { logging: false })
  await Transaction.bulkCreate(transactions, { logging: false })
  await printKnownDeposit();
  await printUnknownDeposit();
  await printMaxDeposit();
  await printMinDeposit();
}
processTransactions().then(()=>{
  return sequelize.close()
}).then(()=>{
  process.exit()
}).catch(error=>{
  console.error(error)
});