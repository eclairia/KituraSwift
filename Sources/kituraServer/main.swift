import SwiftKuery
import SwiftKueryPostgreSQL
import HeliumLogger
import Kitura
import KituraStencil

// router config
HeliumLogger.use()

let router = Router()

class Users : Table {
    let tableName = "users"
    let id_users = Column("id_users", Int64.self, autoIncrement: true, primaryKey: true)
    let name = Column("name", Varchar.self, length: 50)
    let password = Column("password", Varchar.self, length: 100)
}

class Messages : Table {
    let tableName = "messages"
    let messages_id = Column("messages_id", Int64.self, autoIncrement: true, primaryKey: true)
    let users_id = Column("users_id", Int64.self)
    let content = Column("content", Varchar.self, length: 255)
}

let users = Users()

let messages = Messages()

let connection = PostgreSQLConnection(host: "localhost", port: 5432, options: [.databaseName("tchat")])

connection.connect() { error in
    if error != nil {
        print("We have errors")
    } else
    {
        users.create(connection: connection) { (result) in
            print(result)
        }
        
        messages.create(connection: connection) { (result2) in
            print(result2)
        }
        
        connection.closeConnection()
    }
}

func users(_ callback:@escaping (String)->Void) -> Void {
    connection.connect() { error in
        if let error = error {
            callback("Error is \(error)")
            return
        }
        else {
            // Build and execute your query here.
            
            // First build query
            let query = Select(users.name, from: users)
            
            connection.execute(query: query) { result in
                if let resultSet = result.asResultSet {
                    var retString = ""
                    
                    for title in resultSet.titles {
                        // The column names of the result.
                        retString.append("\(title)")
                    }
                    retString.append("\n")
                    
                    for row in resultSet.rows {
                        for value in row {
                            if let value = value {
                                let valueString = String(describing: value)
                                retString.append("\(valueString)")
                            }
                        }
                        retString.append("\n")
                    }
                    callback(retString)
                }
                else if let queryError = result.asError {
                    // Something went wrong.
                    callback("postgresql problem \(queryError)")
                }
            }
        }
    }
}

func messages(_ callback:@escaping (String)->Void) -> Void {
    connection.connect() { error in
        if let error = error {
            callback("Error is \(error)")
            return
        }
        else {
            // Build and execute your query here.
            
            // First build query
            let query = Select(messages.messages_id, messages.users_id, messages.content, from: messages)
            
            connection.execute(query: query) { result in
                if let resultSet = result.asResultSet {
                    var retString = ""
                    
                    for title in resultSet.titles {
                        // The column names of the result.
                        retString.append("\(title)")
                    }
                    retString.append("\n")
                    
                    for row in resultSet.rows {
                        for value in row {
                            if let value = value {
                                let valueString = String(describing: value)
                                retString.append("\(valueString)")
                            }
                        }
                        retString.append("\n")
                    }
                    callback(retString)
                }
                else if let queryError = result.asError {
                    // Something went wrong.
                    callback("postgresql problem \(queryError)")
                }
            }
        }
    }
}

router.all(middleware: [BodyParser(), StaticFileServer(path: "./Public")])
router.setDefault(templateEngine: StencilTemplateEngine())

router.get("/") { request, response, next in
    users() {
        resp in
        response.send(resp)
    };
    
    messages() {
        resp in
        response.send(resp)
        next()
    }
}

router.get("/add_user") { request, response, next in
    try response.render("state", context: ["test": ""])
}

router.post("/insert_user") { request, response, next in
    guard let body = request.body else {
        try response.status(.badRequest).end()
        return
    }
    
    guard case .urlEncoded(let data) = body else {
        try response.status(.badRequest).end()
        return
    }
    
    let name = data["name"]
    let password = data["password"]
    
    connection.connect() { error in
        if error != nil {
            print("We can't make the database connection")
            return
        }
        else {
            let query = Insert(into: users, valueTuples: [(users.name, name), (users.password, password)])
            connection.execute(query: query) {
                result in
                    print(query)
        
                connection.closeConnection()
            }
            
            connection.execute(query: query) { result in
                do {
                    switch result {
                    case .error:
                        print(error as Any)
                    default:
                        print(error as Any)
                    }
                    try response.redirect("/").end()
                }
                catch {
                    print("error")
                }
            }
        }
    }
}

router.get("/add_message") { request, response, next in
    try response.render("message", context: ["test": ""])
}

router.post("/insert_message") { request, response, next in
    guard let body = request.body else {
        try response.status(.badRequest).end()
        return
    }
    
    guard case .urlEncoded(let data) = body else {
        try response.status(.badRequest).end()
        return
    }
    
    let users_id = data["id_user"]
    let content = data["content"]
    
    connection.connect() { error in
        if error != nil {
            print("We can't make the database connection")
            return
        }
        else {
            let query = Insert(into: messages, valueTuples: [(messages.users_id, users_id), (messages.content, content)])
            connection.execute(query: query) {
                result in
                print(query)
                
                connection.closeConnection()
            }
            
            connection.execute(query: query) { result in
                do {
                    switch result {
                    case .error:
                        print(error as Any)
                    default:
                        print(error as Any)
                    }
                    try response.redirect("/").end()
                }
                catch {
                    print("error")
                }
            }
        }
    }
}

// Add an HTTP server and connect it to the router
Kitura.addHTTPServer(onPort: 8080, with: router)

// Start the Kitura runloop (this call never returns)
Kitura.run()
