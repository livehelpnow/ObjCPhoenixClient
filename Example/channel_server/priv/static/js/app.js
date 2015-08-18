import {Socket} from "deps/phoenix/web/static/js/phoenix"

let socket = new Socket("/socket")
socket.connect()
//let chan = socket.channel("rooms:lobby", {})
//chan.join().receive("ok", chan => {
//  console.log("Welcome to Phoenix Chat!")
//})
