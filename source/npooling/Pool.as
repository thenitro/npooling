package npooling {
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

        /*
            DEPRECATED
         */
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
		
		public function get(pClass:Class, pAutoAllocate:Boolean = true):IReusable {
			var subPool:SubPool = _classes[pClass] as SubPool;

            if (!subPool) {
                if (pAutoAllocate) {
                    allocate(pClass, 1);
                    subPool = _classes[pClass] as SubPool;
                } else {
                    return null;
                }
            }

            var item:IReusable

            if (subPool.size) {
                item = subPool.get();

                if (item.disposed) {
                    throw new Error('There is problem with pooling: a wild disposed object appears!');
                }
            } else if (pAutoAllocate) {
                item = new pClass();
            }

            return item;
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