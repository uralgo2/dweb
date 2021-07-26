module dweb.utils;

import std.conv;
import std.array;
import std.stdio;
import std.socket;
import dweb.view_engine : Options;
import dweb.server : HttpServer;

public class Request{
	public string Method;
	public string Path;
	public string[string] Params;
	public string Body;
	public Header[] Headers;
}

public class Response{
	private string Status;
	private Socket client;
	private Header[string] Headers;
	private char[] Body;
	public bool isSended;
	private HttpServer server;
	this(Socket client, HttpServer server){
		this.Status = "200 OK";
		this.client = client;
		this.Body = [];
		this.isSended = false;
		this.server = server;
	}
	public void setHeader(string Name, string Value){
		Header header;
		header.Name = Name;
		header.Value = Value;
		this.Headers[Name] = header;
	}
	public void setStatus(int status){
		this.Status = status.to!string();
	}
	public void text(string val){
		this.Body ~= val;
	}
	public void fhtml(string name){
		Header head;
		head.Name = "Content-Type";
		head.Value = "text/html; charset=utf-8";
		this.Headers[head.Name] = head;
		auto f = File(name, "r");
		string str;
		f.readf!"%s"(str);
		this.Body ~= str;
		f.close();
	}
	public void send(){
		char[] data = this.serializeResponse();
		ptrdiff_t sended = this.client.sendTo(data);
		this.isSended = true;
	}
	public void send(string b){
		this.Body ~= b.dup;
		char[] data = this.serializeResponse();
		ptrdiff_t sended = this.client.sendTo(data);
		this.isSended = true;
	}
	public void send(int b){
		this.Status = b.to!string();
		char[] data = this.serializeResponse();
		ptrdiff_t sended = this.client.sendTo(data);
		this.isSended = true;
	}
	private char[] serializeResponse(){
		string text = "HTTP/1.1 " ~ this.Status ~ "\r\n";
		Header head;
		head.Name = "Content-Length";
		head.Value ~= this.Body.length.to!string();
		this.Headers[head.Name] = head;
		
		foreach(header; this.Headers){
			text ~= header.Name ~ ": " ~ header.Value ~ "\r\n";
		}
		text ~= "\r\n";
		text ~= this.Body;

		char[] res = cast(char[])text;
		return res;
	}
	public void render(string data, Options options = null){
		if(options !is null)
			this.server.view_engine.setOptions(options);
		this.Body ~= this.server.view_engine.render(data);
		this.send();
	}
	public void frender(string filename, Options options = null){
		if(options !is null)
			this.server.view_engine.setOptions(options);
		auto f = File(filename, "r");
		
		string str;
		f.readf!"%s"(str);
		f.close();

		this.Body ~= this.server.view_engine.render(str);
		this.send();
	}
}
public struct Header{
	string Name;
	string Value;
}

Request parseRequest(char[] buffer){
	Request req = new Request();
	string raw_path;
	char[] Name;
	char[] Value;
	ubyte mode; // 0 - name; 1 - value
	string rawtext = text(buffer);
	string[] raw = rawtext.split("\r\n");
	req.Method = raw[0].split(' ')[0];
	req.Path = raw[0].split(' ')[1].split("?")[0];
	raw_path = raw[0].split(' ')[1];
	string[] raw_ = raw[1 .. raw.length];
	uint last = 0;
	for(uint i = 0; i < raw_.length; i++){
		string raw_str = raw_[i];
		if(raw_str == ""){
			last = i + 1;
			break;
		}
		string[] s = raw_str.split(": ");
		if(s.length > 1){
			Header header;
			header.Name = s[0];
			header.Value = s[1];
			req.Headers ~= [header];
		}
	}
	if(last != 0){
		req.Body = raw_[last .. raw_.length].join("\r\n");
		if(req.Method == "GET" && raw_path.split("?").length > 1){
			string[] val = raw_path.split("?")[1].split("&");

			foreach(v; val){
				string[] keyval = v.split("=");
				if(keyval.length <= 1){
					req.Params[keyval[0]] = "";
				}
				else if(keyval.length > 1){
					req.Params[keyval[0]] = keyval[1];
				}
			}
		}
	}

	return req;
}



bool containsKeyAssoc(TKey, TValue)(TKey need, TValue[TKey] arr){
	foreach(pair; arr.byPair){
		if(pair.key == need)
			return true;
	}
	return false;
}
 