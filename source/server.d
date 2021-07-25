module dweb.server;

import std.socket;
import std.stdio;
import std.array;
import std.conv;
import dweb.utils;
import dweb.view_engine;

public class HttpServer{
	private Address address;
	private Socket socket;
	private void function(Request, Response)[string] gettable;
	private void function(Request, Response)[string] posttable;
	private void function(Request, Response) notf;
	private void function(Request, Response, void function(Request, Response)) ever;
	public ViewEngine view_engine;
	this(string host, ushort port){
		this.address = new InternetAddress(host, port);
		this.socket = new TcpSocket(AddressFamily.UNSPEC);
		this.socket.bind(this.address);
		this.notf = &nf;
		this.view_engine = new ViewEngine();
		this.ever = null;
	}
	public void setViewEngine(ViewEngine newve){
		this.view_engine = newve;
	}
	public void listen(){
		this.socket.listen(0);
		while(true){
			Socket client = this.socket.accept();
			char[] buffer = new char[1024 * 1024];
			uint received = client.receive(buffer).to!uint();
			if(received != 0){
				buffer = buffer[0 .. received];
				Request req = parseRequest(buffer);
				Response res = new Response(client, this);

				res.setHeader("Content-Type", "text/html; charset=utf-8");

				if(req.Method == "GET"){
					
					if(containsKeyAssoc!(string, void function(Request, Response))(req.Path, gettable)){
						if(ever !is null)
							ever(req, res, gettable[req.Path]);
						else
							gettable[req.Path](req, res);
					}
					else
						notf(req, res);
				}
				else if(req.Method == "POST"){
					if(containsKeyAssoc!(string, void function(Request, Response))(req.Path, posttable)){
						if(ever !is null)
							ever(req, res, posttable[req.Path]);
						else
							posttable[req.Path](req, res);
					}
					else
						notf(req, res);
				}
				if(!res.isSended){
					res.send();
				}
				client.shutdown(SocketShutdown.BOTH);
				client.close();
			}
			
		}
	}
	public void get(string path, void function(Request, Response) cb){
		gettable[path] = cb;
	}
	public void post(string path, void function(Request, Response) cb){
		posttable[path] = cb;
	}
	public void notfound(void function(Request, Response) cb){
		this.notf = cb;
	}
	
}
void nf(Request req, Response res){
	res.text("<center style=\"margin-top: 30vh;\">");
	res.text("<h1>404 Not Found</h1>");
	res.text("<h3>Path \"" ~ req.Path ~ "\" not found");
	res.text("</center>");
	res.send(404);
}