# What is this?

ahut is a sports log system with a focus on the experience of the activity. You can have multiple sports within the same log file and you log lives in one uniform data file that you maintain and own.

Sport apps like Endomondo, Strava, Garmin Connect come and go and when they go, you risk loosing all your hard earned data with it. It happened to us on several occassions. This is annoying as the logging of some sports (particularly adventure type sports) have good value over time. In sports like climbing, caving, snowboarding, kayaking we find it valuable to know what we did when revisiting a crag, cave or site. Or to know what we did with a certain partner over time. In our experience the partners you do sports with often end up being your long term friends, and the topic of "remember that time with did..." pops up often in conversations down the pub or round the bbq and just like any other encylopedea it is nice to be able to consult the truth somewhere when memeory may fail. 

While we ourselves have practiced a handfull of specific sports (climbing, caving, kayaking, snowboarding, kitesurfing, sailing, running, paragliding) you can decide which sport or sports you want to figure in your system - as long as it follows a certain template
```
Date; Area; Activity name; Grade; Length; People; Quality; External References; Comments
```
Your log entry does not have to have all the parameters (you just leave it blank) and the format within each field is fairly flexible. In the Quality field you can have add a number of icons with meanings like "Top100, Mindblower, Desperate" and more. Area and People field references a list of areas and a list of people within the file.
Examples (climbing)
```
13-05-2022; BH; Tabu Crack; E1 5b; 20m; TW; <3S><A><M>; <P http://img.url/324fm3>; Awesome route. Hard crux mid way.
```
or (caving)
```
14-05-2022; MD; Goatchurch Cavern; ; 3h; PW TW; <2S><2>; <N http://report.nu/324fm3>;
```
or (diving)
```
05-11-1997; IN; Tulamben; ; 15m; FW; <6>
```
# prep

install http-server
```
npm install http-server --global 
```

# Generate files

```
perl climbs.pl
```

# View locally
```
cd html
http-server .
```

Go to: http://localhost:8080/mw-climbs.html
(or whichever hostname/port the http-server says we are using)


Jeg ved ikke helt hvordan jeg skal beskrive "hut 4.0 - en ny begyndelse". Men jeg prøver:

Jeg har leget lidt data arkeolog over julen, primært drevet af en fornyet entusiasme i UV klubben, hvor jeg satte mig for at gen-finde de gamle referater. Det var en søgen i mange systemer, mange databaser og uddaterede systemer. Det lykkedes og værdien i arkivet er virkelig høj. Det slog mig, da jeg havde genskabt det meste, at værdien i at have en "notes bog" eller log bog både kommer til sin ret i nuet og også, når det er et arkiv. 

Næste arkelogiske øvelse var klatreloggen, som lå i ruiner i mange forskellige velmenende systemer - for mit vedkomne i de 3 versioner af ahut vi selv har lavet, og så suppleret op med logging i ukclimbing, 27crags, et masser emails, flickr og andet. 

Da jeg begyndte at konsolidere csv filer og andet udtræk i mw-climbs.txt så var der en enorm tilfredstillelse og "tryghed" ved at have een fil med alt mit dyrebare log i. Een fil som kan læses uden brug af databasesystemer. Jeg har efterfølgende proppet min caving log, min kitelog (fra ikitesurfmag på facebook som havde et fedt log system), min paragliding log (fra google sheets) og andet. Fælles for min log er at det er aktiviteter som jeg ser tilbage på med minder - ikke træningsløbeturen rundt om blokken (strava) men der hvor der var noget på spil (oprindelig ahut ide).

Nu sidder jeg så med mw-climbs og et perlscript og laver de vildeste udtræk og views og får det lige som jeg vil ha' det - uden at være db-udvikler og med lidt snørklet perlscripting, men utroligt hurtigt og nemt at arbejde med - jeg prøver et variabel af og kører perl, og så kan jeg med det samme se og det virkede eller ej. Det er brugervenligt og brugbart.

Så jeg tænkte at man burde tilbyde et "tick/log/track" system bygget på opensource perl agtig tilgang, til at starte med i stil med det du har lavet med climbs.pl. Lave det på en måde så det er mere optimeret til at håndtere forskellige aktivitetstyper, men med fokus på at have et ensartet format - skræl alt ned til hvad der er af værdi 20 år efter. I et dyk er det nok hvor dybt og hvorlænge man var under, og ikke hvormange bar man havde tilbage i flasken. Og så billeder! Jeg har lykkedes med at ploppe billeder ind i loggen, og det giver en kæmpe værdi. Det gør at billedet af os foran goatchurch i 1994 nu er i kontekst istedet for sit ensomme liv i blandt 15000 billeder på flickr eller google photos.

Man kunne så lege med at lave nogle frontend-s til kerne-filen. - et OSX, Windows, Linux app som gør det nemt at redigere filen og publishe. Måske koblet til en server så man kan tilbydes at publishe sin log-fil i fedt web format på en side - tiklog.com?

Der er et problem i at lade sin historiske data leve som posts' på facebook, i et par amatøres log-system, eller i andres dybe database arkiver.

Hvis man en dag havde et fuld-fledged system så kunne det sikkert koble sig op til eksisterende "dive logs, endomodos, stravas etc" og så hive ens data ned i denne ene txt-fil. Denne txt-fil kunne så publishes med førnævnte suite af apps.

Sidste betragtning: hvis det så er "nuet" man logger - feks hvis Axel og jeg er ude og cave i april, så vil jeg jo som regel gerne "dele det med alle". Her tænker jeg også at det er fedt at dele "links til min log" istedet for at logge det på eg. facebook. Hvis man laver det lækkert, så er det nemt at dele det i facebook, mails og sms og messenger threads. Jeg oplever flere og flere der ikke er på facebook eller andet, og der er det fedt at kunne dele sin weekend oplevelse fra et sted til flere platforme. 

Nedenstående er et "paste" fra min logfil - se hvor lækkert det formatere sig, uden jeg gjorde andet en copy paste - til dels fordi koden er lavet uden gif-fils-ikoner og med super simpel html.
