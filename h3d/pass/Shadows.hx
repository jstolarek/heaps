package h3d.pass;

enum RenderMode {
	None;
	Static;
	Dynamic;
	Mixed;
}

class Shadows extends Default {

	var format : hxd.PixelFormat;
	public var mode(default,set) : RenderMode = None;
	public var size(default,set) : Int = 1024;
	public var shader(default,null) : hxsl.Shader;
	public var blur : Blur;

	public function new() {
		if( format == null ) format = R16F;
		if( !h3d.Engine.getCurrent().driver.isSupportedFormat(format) ) format = h3d.mat.Texture.nativeFormat;
		super("shadows");
		blur = new Blur(5);
		blur.quality = 0.5;
		blur.shader.isDepth = format == h3d.mat.Texture.nativeFormat;
	}

	function set_mode(m:RenderMode) {
		if( m != None ) throw "Shadow mode "+m+" not supported for "+this;
		return mode = m;
	}

	function set_size(s) {
		return size = s;
	}

	override function dispose() {
		super.dispose();
		blur.dispose();
	}

	override function getOutputs() : Array<hxsl.Output> {
		if( format == h3d.mat.Texture.nativeFormat )
			return [PackFloat(Value("output.depth"))];
		return [Swiz(Value("output.depth",1),[X,X,X,X])];
	}

	public function computeStatic( passes : h3d.pass.Object ) {
		throw "Not implemented";
	}

	function filterPasses( passes : h3d.pass.Object ) : h3d.pass.Object {
		var isStatic : Bool;
		switch( mode ) {
		case None:
			return null;
		case Dynamic:
			if( ctx.computingStatic ) return null;
			return passes;
		case Mixed:
			isStatic = ctx.computingStatic;
		case Static:
			if( !ctx.computingStatic ) return null;
			isStatic = true;
		}
		var head = null;
		var prev = null;
		var last = null;

		var cur = passes;

		var count = 0;
		while( cur != null )  {
			if( cur.pass.isStatic == isStatic )
				count++;
			cur = cur.next;
		}
		cur = passes;

		while( cur != null ) {
			if( cur.pass.isStatic == isStatic ) {
				if( head == null )
					head = prev = cur;
				else {
					prev.next = cur;
					prev = cur;
				}
			} else {
				if( last == null )
					last = cur;
				else {
					last.next = cur;
					last = cur;
				}
			}
			cur = cur.next;
		}
		if( last != null )
			last.next = head;
		if( prev != null )
			prev.next = null;


		cur = head;
		while( cur != null )  {
			if( cur.pass.isStatic != isStatic ) throw "assert";
			count--;
			cur = cur.next;
		}
		if( count != 0 ) throw "assert";

		return head;
	}

}