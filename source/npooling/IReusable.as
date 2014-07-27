package npooling {
	public interface IReusable {
		function get reflection():Class;
        function get disposed():Boolean;
		function poolPrepare():void;
		function dispose():void;
	};
}