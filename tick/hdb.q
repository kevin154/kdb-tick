// Sample usage:
// q hdb.q C:/OnDiskDB/sym -p 5002

// Check hdb dir is passed in
if[not count .z.x; 
    show "Supply directory of historical database";
	exit 0
 ];

// HDB dir should be first 
hdb:.z.x 0;

// Mount the Historical Database
@[{system "l ", x};hdb;{show "Error message - ", x;exit 0}];