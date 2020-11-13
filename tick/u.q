/2019.06.17 ensure sym has g attr for schema returned to new subscriber
/2008.09.09 .k -> .q
/2006.05.08 add

\d .u


// .u.init - initialises .u.w, the list of tables mapped to its corresponding subscribers and syms they are subscribed to
init:{
    w::t!(count t::tables `.)#()
};


// .u.del - removes a handle from the list of subscribers to a table 
// @Params:
// x - the table to unsubscribe to 
// y - the handle unsubscribing to the table
del:{w[x]_:w[x;;0]?y};


// Whenever a downstream connection closes, remove all table subscriptions
.z.pc:{del[;x] each t};


// .u.sel - used by .u.pub to filter data on certain syms
// @Params:
// x - table to filter
// y - list of syms to filter on
// @Return: Data from table x filtered on syms y
sel:{
    // If list of sym subscriptions is null sym return full table, else filter on given syms
    $[`~y;
        x;
	select from x where sym in y
    ]
};

// .u.pub - publishes data out to subscribers 
// @Params:
// t - table to publish
// x - data to publish
pub:{[t;x]
    // Inner function called seperately for each subscriber w in .u.w
    {[t;x;w]
        // Filter the data for the syms that the subsciber has requested
	// Pass the filtered table data to the upd function on the subscriber process downstream
	if[count x:sel[x] w 1;
	    (neg first w)(`upd;t;x)
        ]
    }[t;x] each w t
};

// .u.add - adds to list of subscribers, called by .u.sub
// @Params:
// x - table to subscribe to
// y - syms to subscribe to
add:{
    // Check if subscriber has existing subscription
    i:w[x;;0]?.z.w;
    // If a subscription exists combine with new requested syms, else add new subscription
    $[(count w x) > i;
        .[`.u.w;(x;i;1);union;y];
        w[x],:enlist(.z.w;y)
    ];
    // Return the table name and table schema
    (x;$[99=type v:value x;sel[v]y;@[0#v;`sym;`g#]])
 };

// .u.sub 
// @Params:
// x - table to subscribe to
// y - syms to subscribe to
sub:{
    // If table is empty subscribe to all tables for given sym  
    if[x~`;
        :sub[;y] each t
    ];
    // If table name doesn't exist throw error
    if[not x in t;
        'x
    ];
    // Delete any existing subscriptions for subscriber	
    del[x].z.w;
    // Add new subscription
    add[x;y]
};

// .u.end
end:{(neg union/[w[;;0]])@\:(`.u.end;x)};
