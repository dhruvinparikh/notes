// Design an expense sharing system


/*
 Input:
   * 1. Main user that is paying the amount
   * 2. Amount
   * 3. users included in the payment
   * 4. Shares of each user
       ** Can be Equal
       ** Can be Exact
       ** Can be Percentage
   * 5. Metadata about the expense
*/

/*
Output:
 1. Overall summary
 2. Individual summary
 3. Output all the expenses a given user is involved in
*/

/* Examples
* Step - 1 | A pays 1000 for a payment with B, C, D included -> All shares are equal  (1000 / 4)
   <summary>
       B owes A 250
       C owes A 250
       D owes A 250
   </summary>
   <user B - summary>
       B owes A 250
   </user B - summary>
 
* Step - 2 | B pays 1000 for a payment with A, C included -> A shares 300, C shares 500
   <summary>
       A owes B 50 (300 - 250)
       C owes A 250
       C owes B 500
       D owes A 250
   </summary>
   <user A - summary>
       A owes B 50
       C owes A 250
       D owes A 250
   </user A - summary>
   
* Step - 3 | C pays 1000 for a payment with A, B, D included -> A percentage 25, B percentage 30, D percentage 10
   <summary>
       A owes B 50 (300 - 250)
       C owes B 200
       D owes A 250
       D owes C 100
   </summary>
   <user A - summary>
       A owes B 50
       D owes A 250
   </user A - summary>
   <user A - expenses>
      1. A Pays 1000 with B, C and D (EQUAL)
      2. B Pays 1000 with A and C (EXACT => A = 300 C = 500)
      3. C Pays 1000 with A, B and D (PERCENTAGE => A = 25 B = 30 D = 10)
   </user A - expenses>
*/

class ExpenseTracker {

    someVar = {};
    expenseList = {}

    add(expense) {
        const payer = expense.payer;
        const amount = expense.amount;
        const payees = expense.payees;
        const expenseType = expense.expenseType
        const metadata = expense.metadata

        switch (expenseType) {
            case "equal":
                const contribution = amount / (payees.split(",").length + 1)
                if (typeof this.expenseList[payer] !== "object") {
                    this.expenseList[payer] = []
                }
                this.expenseList[payer].push({
                    expenseType,
                    amount,
                    payees
                })
                for (const payee of payees.split(",")) {
                    if (typeof this.someVar[payee] !== "object") {
                        this.someVar[payee] = {};
                    }
                    if (!this.someVar[payee][payer]) {
                        this.someVar[payee][payer] = 0;
                    }
                    if (typeof this.someVar[payer] !== "object") {
                        this.someVar[payer] = {};
                    }
                    if (!this.someVar[payer][payee]) {
                        this.someVar[payer][payee] = 0;
                    }
                    this.someVar[payee][payer] = this.someVar[payee][payer] + contribution
                    this.someVar[payer][payee] = this.someVar[payer][payee] - contribution
                }
                break;
            case "exact":
                if (typeof this.expenseList[payer] !== "object") {
                    this.expenseList[payer] = []
                }
                this.expenseList[payer].push({
                    expenseType,
                    amount,
                    payees
                })
                for (const payee of Object.keys(payees)) {
                    if (typeof this.someVar[payee] !== "object") {
                        this.someVar[payee] = {};
                    }
                    if (!this.someVar[payee][payer]) {
                        this.someVar[payee][payer] = 0;
                    }
                    if (typeof this.someVar[payer] !== "object") {
                        this.someVar[payer] = {};
                    }
                    if (!this.someVar[payer][payee]) {
                        this.someVar[payer][payee] = 0;
                    }
                    this.someVar[payee][payer] += payees[payee]
                    this.someVar[payer][payee] -= payees[payee]
                }
                break;
            case "percentage":
                if (typeof this.expenseList[payer] !== "object") {
                    this.expenseList[payer] = []
                }
                this.expenseList[payer].push({
                    expenseType,
                    amount,
                    payees
                })
                for (const payee of Object.keys(payees)) {
                    if (typeof this.someVar[payee] !== "object") {
                        this.someVar[payee] = {};
                    }
                    if (!this.someVar[payee][payer]) {
                        this.someVar[payee][payer] = 0;
                    }
                    if (typeof this.someVar[payer] !== "object") {
                        this.someVar[payer] = {};
                    }
                    if (!this.someVar[payer][payee]) {
                        this.someVar[payer][payee] = 0;
                    }
                    this.someVar[payee][payer] += amount * payees[payee]/100
                    this.someVar[payer][payee] -= amount * payees[payee]/100
                }
                break;
            default:
                throw Error("Invalid expense type")
        }
    }

    getUserSummary(_user) {
        return this.someVar[_user]
    }

}

class Expense {
    constructor(_payer, _amount, _payees, _expenseType, _metadata) {
        this.payer = _payer;
        this.amount = _amount;
        this.payees = _payees;
        this.expenseType = _expenseType;
        this.metadata = _metadata;
    }
}

class User {

    constructor(_name) {
        this.name = _name
    }
}

function test() {

    const expenseTracker = new ExpenseTracker();

    const expense1 = new Expense("Alice", 1000, "Bob,Charlie,Dave", "equal", "");
    const expense2 = new Expense("Bob", 1000, { "Alice": 300, "Charlie": 500 }, "exact", "")
    const expense3 = new Expense("Charlie", 1000, { "Alice": 25, "Bob": 30, "Dave": 10 }, "percentage", "")

    expenseTracker.add(expense1)
    for(const userO of Object.keys(expenseTracker.someVar)){
        for(const userI of Object.keys(expenseTracker.someVar[userO])){
            if(expenseTracker.someVar[userO][userI] > 0){
                console.log(`${userO} owes to ${userI} ${expenseTracker.someVar[userO][userI]}`)
            }
        }
    }
    expenseTracker.add(expense2)
    console.log("=====================")
    for(const userO of Object.keys(expenseTracker.someVar)){
        for(const userI of Object.keys(expenseTracker.someVar[userO])){
            if(expenseTracker.someVar[userO][userI] > 0){
                console.log(`${userO} owes to ${userI} ${expenseTracker.someVar[userO][userI]}`)
            }
        }
    }
    expenseTracker.add(expense3)
    console.log("=====================")
    for(const userO of Object.keys(expenseTracker.someVar)){
        for(const userI of Object.keys(expenseTracker.someVar[userO])){
            if(expenseTracker.someVar[userO][userI] > 0){
                console.log(`${userO} owes to ${userI} ${expenseTracker.someVar[userO][userI]}`)
            }
        }
    }
    console.log("=====================")
    const expenses = expenseTracker.expenseList;
    for(const payer of Object.keys(expenses)){
        for (let i = 0 ; i<expenses[payer].length  ;i++) {
        switch (expenses[payer][i].expenseType) {
            case "equal":{
                console.log(`${payer} Pays ${expenses[payer][i].amount} with ${expenses[payer][i].payees} (EQUAL)`)
                break;
            }
            case "exact":{
                console.log(`${payer} Pays ${expenses[payer][i].amount} with ${Object.keys(expenses[payer][i].payees)} (EXACT => ${Object.values(expenses[payer][i].payees)} respectively)`)
                break;
            }
            case "percentage":{
                console.log(`${payer} Pays ${expenses[payer][i].amount} with ${Object.keys(expenses[payer][i].payees)} (PERCENTAGE => ${Object.values(expenses[payer][i].payees)} respectively)`)
                break;
            }
        }
    } 
    }
}

test();