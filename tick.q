/ q tick.q sym . -p 5001 </dev/null >foo 2>&1 &
/2014.03.12 remove license check
/2013.09.05 warn on corrupt log
/2013.08.14 allow <endofday> when -u is set
/2012.11.09 use timestamp type rather than time. -19h/"t"/.z.Z -> -16h/"n"/.z.P
/2011.02.10 i->i,j to avoid duplicate data if subscription whilst data in buffer
/2009.07.30 ts day (and "d"$a instead of floor a)
/2008.09.09 .k -> .q, 2.4
/2008.02.03 tick/r.k allow no log
/2007.09.03 check one day flip
/2006.10.18 check type?
/2006.07.24 pub then log
/2006.02.09 fix(2005.11.28) .z.ts end-of-day
/2006.01.05 @[;`sym;`g#] in tick.k load
/2005.12.21 tick/r.k reset `g#sym
/2005.12.11 feed can send .u.endofday
/2005.11.28 zero-end-of-day
/2005.10.28 allow`time on incoming
/2005.10.10 zero latency
"kdb+tick 2.8 2014.03.12"

/q tick.q SRC [DST] [-p 5010] [-o h]

// Load schema file
src:first .z.x;
system "l tick/", src, ".q"

// If tickerplant port not set, set to default 5010
if[not system "p";system "p 5010"];

// Load utility functions
\l tick/u.q

// Ensure .u namespace is set
\d .u

// .u.ld - initialises TP log file
// @Params: 
// x: The current date
// @Returns: The handle to the log file
ld:{
    // Check if TP log .u.L exists, create new one if not
    if[not type key L::`$(-10_string L), string x;
        .[L;();:;()]
	];
	// Read valid chunks of the log file
	i::j::-11!(-2;L);
	// If invalid entries found then log and exit
	if[0<=type i;
	    -2 (string L)," is a corrupt log. Truncate to length ", (string last i), " and restart";
		exit 1
	];
	// Open log handle for writing
	hopen L
 };

// .u.tick - initialises variables and log file and checks table validity
// @Params:
// x - the file name containing the table schemas (variable src) 
// y - the log file directory
tick:{
	init[];
	// Ensure each table has both a time and sym column
	if[not min(`time`sym~2#key flip value@)each t;
	    '`timesym
    ];
	// Apply the grouped attribute to the sym column of each table
	@[;`sym;`g#] each t;
	// Set .u.d to today's date
	d::.z.D;
	// If the log file directory is populated then initialise it 
	if[l::count y;
	    L::`$":", y, "/", x, 10#".";
		l::ld d
    ]
 };

// .u.endofday - end of day function for rolling over to new TP log file
// @Params:
// None
endofday:{
    // Call .u.end for current date .u.d
    end d;
	// Increment current date
	d+:1;
	// If the handle to the current log file is open then close it and initialise new log with new date
	if[l;
	    hclose l;
		l::0(`.u.ld;d)
    ]
 };

// .u.ts - date check wrapper function around .u.endofday 
// @Params: 
// x - date to check
ts:{
    // If new date is not greater than current date .u.d then exit
    if[d<x;
	    // If new date is more than one day ahead of current day stop timer and throw an error
	    if[d<x-1;
		    system "t 0";
			'"more than one day?"
		];
	    endofday[]
	]
 };


if[system "t";
    
    // Set timer functionality
    .z.ts:{
        // Publish current table data to corresponding subscribers
	pub'[t;value each t];
	// Purge table data and reset grouped attribute on sym columns
	@[`.;t;@[;`sym;`g#]0#];
	// Update TP log msg count 
	i::j;
	// Check if EOD needs to be called
	ts .z.D
    };

    // .u.upd - function called by upstream feedhandler
    // @Params
    // t - table to update
    // x - data to add to table
    upd:{[t;x]
        
        // Check if the data has a time column
	if[not -16=type first first x;
	    // 'a' is current timestamp
	    a:.z.P;
	    // Check if EOD needs to be run
	    if[d < "d"$a;
	        .z.ts[]
	    ];
	    // Cast 'a' to a timespan
	    a:"n"$a;
	    // Prepend the current timespan to each data element
	    x:$[0 > type first x;
	         a, x;
		 (enlist(count first x)#a), x
	    ]
	];
		
        t insert x;
	// If the TP file handle is open update the log and increment running count 
	if[l;
	    l enlist (`upd;t;x);
	    j+:1
        ];
    }
];

if[not system "t";
    
    // If timer has not been set, set to one second
    system "t 1000";

    // Set timer to check for EOD   
    .z.ts:{ts .z.D};
    
    // .u.upd - function called by upstream feedhandler
    // @Params
    // t - table to update
    // x - data to add to table
    upd:{[t;x]
	    
        // 'a' is current timestamp
	a:.z.P;
		
	// Check if EOD needs to be run
	ts "d"$a;
		
	// Check if the data has a time column
        if[not -16=type first first x;
		    
	    // Cast 'a' to a timespan
	    a:"n"$a;
	    // Prepend the current timespan to each data element
	    x:$[0>type first x;
	        a, x;
		(enlist(count first x)#a),x
	    ]
	];
		
	// The table columns
        f:key flip value t;
	// Add the table columns to the data and publish table
	pub[t;$[0>type first x;enlist f!x;flip f!x]];
		
	// If the TP file handle is open update the log and increment running count 
	if[l;
	    l enlist (`upd;t;x);
	    i+:1
	];
    }
 ];

\d .

// Call .u.tick to initialise everything
.u.tick[src;.z.x 1];

\
 globals used
 .u.w - dictionary of tables->(handle;syms)
 .u.i - msg count in log file
 .u.j - total msg count (log file plus those held in buffer)
 .u.t - table names
 .u.L - tp log filename, e.g. `:./sym2008.09.11
 .u.l - handle to tp log file
 .u.d - date
/test
>q tick.q
>q tick/ssl.q
/run
>q tick.q sym  .  -p 5010	/tick
>q tick/r.q :5010 -p 5011	/rdb
>q sym            -p 5012	/hdb
>q tick/ssl.q sym :5010		/feed
