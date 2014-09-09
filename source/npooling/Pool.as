package npooling {

    import com.thenitro.ngine.particles.abstract.particles.ImageParticle;

    import flash.errors.IllegalOperationError;
	import flash.utils.Dictionary;
	
	public final class Pool {
		private static var _instance:Pool;
		private static var _allowInstance:Boolean;
		
		private var _classes:Dictionary;
		
		public function Pool() {
			if (!_allowInstance) throw new IllegalOperationError('Pool: use Pool.getInstance() instead of "new" keyword!');
			
			_classes  = new Dictionary(); 
		};
				
		public static function getInstance():Pool {
			if (!_instance) {
				_allowInstance = true;
				_instance      = new Pool();
				_allowInstance = false;
			}
			
			return _instance;
		};
		
		public function allocate(pClass:Class, pSize:uint):void {
			var subPool:SubPool = _classes[pClass] as SubPool;
			
			if (!subPool) {
				_classes[pClass] = subPool = new SubPool();
			}
			
			subPool.maxSize += pSize;
		};
		
		public function put(pElement:IReusable):void {
			if (!pElement || pElement.disposed) return;
			
			var subPool:SubPool = _classes[pElement.reflection] as SubPool;
			
			if (subPool) {
				if (subPool.inPool(pElement)) {
					return;
				}
				
 				if (subPool.size < subPool.maxSize) {
					subPool.put(pElement);
				} else {
					pElement.dispose();
					pElement = null;
				}
			} else {
				trace('Pool.put: memory not allocated for '
					+ pElement + ' use Pool.allocate() first!');
				
				pElement.dispose();
                pElement = null;
			}
		};
		
		public function get(pClass:Class):IReusable {
			var subPool:SubPool = _classes[pClass] as SubPool;
			
			if (subPool) {
				if (subPool.size) {
                    var item:IReusable = subPool.get();

                    if (item.disposed) {
                        throw new Error('There is problem with pooling: a wild disposed object appears!');
                    }

					return item;
				}
			}
			
			return null;
		};
		
		public function disposeClassInstances(pClass:Class):void {
			var subPool:SubPool = _classes[pClass] as SubPool;
			
			if (subPool) {
				subPool.disposeInstances();
			} else {
				trace('Pool.disposeClassInstances: ' + pClass + 
					' not found in pool. Use allocate() method first!');
			}
		};
	};
}