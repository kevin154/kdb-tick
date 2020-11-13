/q tick/r.q [host]:port[:usr:pwd] [host]:port[:usr:pwd]
/2008.09.09 .k ->.q

// Wait for one second - 'timeout' command for Windows OS, 'sleep' for everything else
$["w"=first string .z.o;
    system "timeout 1";
    system "sleep 1"
];

hdbDir:`$":C:/q/tickDatabase/hdb";

// TP .u.pub calls this function; simply insert data to table
upd:insert;

// Get the ticker plant and history ports, defaults are 5010, 5012
.u.x:.z.x,(count .z.x)_(":5010";":5012");

// .u.end - save, clear, hdb reload
// @Params:
// x - current date
.u.end:{
    // Save table names contained grouped sym attribute
    t:tables `.;
    t@:where `g=attr each t@\:`sym;
    // Saves all tables by calling .Q.dpft, clears tables, and sends reload message to HDB
    // Params - HDB port, HDB directory, HDB partition and field to apply parted attribute
    .Q.hdpf[`$":",.u.x 1;hdbDir;x;`sym];
    // Reapply grouped attribute where applicable
    @[;`sym;`g#] each t
};

// .u.rep - init schema and sync up from log file
// @Params:
// x - list of empty table schemas from TP
// y - list containing (TP log count;TP log location)
.u.rep:{
    // Initialise each table schema
    (.[;();:;].) each x;
    // If log count is null exit 
    if[null first y;
        :()
    ];
    // Populate tables with TP log data
    -11!y;
    // cd to hdb (so client save can run)
    // Assumption is that the HDB is located in <TP log dir>/sym
    system "cd ", 1_-10_string first reverse y
};

// Connect to ticker plant for (schema;(logcount;log))
.u.rep .(hopen `$":",.u.x 0)"(.u.sub[`;`];`.u `i`L)";
