
// Connect to tickerplant
h:neg hopen `::5000

// Stock tickers
syms:`MSFT.O`IBM.N`GS.N`BA.N`VOD.L

// Starting prices
prices:syms!45.15 191.10 178.50 128.04 341.30 

// Number of rows per update
n:2 

// Flag to switch between trade and quote updates
flag:1; 

// Generate random price movements
getmovement:{[s] rand[0.0001]*prices[s]};

// Generate trade price
getprice:{[s] 
    prices[s]+:rand[1 -1]*getmovement[s];
    :prices[s]
 };

// Generate bid price
getbid:{[s] prices[s]-getmovement[s]};

// Generate ask price
getask:{[s] prices[s]+getmovement[s]};

// Timer function
.z.ts:{
    s:n?syms;
    // Generate 10% of updates for trade and 90% for quote
    $[0 < flag mod 10;
        h(".u.upd";`quote;(n#.z.N;s;getbid'[s];getask'[s];n?1000;n?1000));
        h(".u.upd";`trade;(n#.z.N;s;getprice'[s];n?1000))
    ];
    flag+:1
 };

// Trigger timer every 100ms
\t 100
