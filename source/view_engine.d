module dweb.view_engine;

public class ViewEngine{
	private Options options;
	public void setOptions(Options o){
		this.options = o;
	}
	public string render(string html){
		return html;
	}
}

public class Options{
	private string[string] options;
	this(string[string] o){
		this.options = o;
	}
	public string Get(string name){
		return this.options[name];
	}
}