clear; close all;

%{
L'obiettivo del problema è quello di modulare i parametri richiesti per 
sagomare una nuova funzione di anello in modo che essa abbia i valori di
progetto. Lavorerò in una logia ex-ante per poi operare delle verifiche 
finali dopo le quali, se la traccia non è stata rispettata, si potranno 
operare delle modifiche ai valori scelti fino al raggiungimento del
risultato.
%}

% Definisco la variabile che conterrà la funzione di trasferimento

s = zpk('s');
G = 169/(s*(s^2+20*s+169));

%{ 
Dopo aver calcolato il range di valori che il guadagno statico 
può assumere in modo che l'errore sull'uscita, per un disturbo di carico 
a gradino, sia inferiore al 5%, scelgo un valore
C pari a 21. Tramite il comando series costruisco la funzione di
anello che è data dalla serie (detta anche cascata) della funzione di
trasferimento data e il controllore.
%} 
C = 21; % k = 21
L_iniziale = series(C,G);
L_iniziale

%{
Tramite il comando margin, verifico i valori parametri wc, ovvero la pulsazione 
di attraversamento, e la fase che chiamo phi 
%}
figure(1);
margin(L_iniziale);
grid;
legend;

%{
Ottengo un wc = 13.3 rad/s e phi = -1.8° dunque la funzione d'anello non BIBO 
stabile per il criterio di Bode.
Dunque l'algoritmo di controllo dovrà stabilizzare in retroazione il 
sistema oltre che rispettare le specifiche legate alla precisione dinamica.
%}

%{
Il picco di risonanza è definito come il massimo assoluto del diagramma dei
moduli della risposta in frequenza e per essere minore o uguale a 3db devo
calcolare lo smorzamento critico ovvero quel valore che corrisponde
ad un picco di 3dB. Posso compiere il calcolo attraverso la funzione
smorz_Mr
%}
delta_cr = smorz_Mr(3);

%{ 
Ottengo che lo smorzamento critico è pari a 0.3832. Di conseguenza, sapendo
che il margine di fase è 100 volte il valore dello smorzamento critico,
esso sarà pari all'incirca a 39°. 
%}

%{
Considerando il fatto che la pulsazione di attarversamento è un minorante 
della banda passante, dopo vari tentativi, concludo che è buon valore a cui 
porla è 6.3 rad/s.
Procedo ora a calcolare i valori della funzione di anello tenendo in 
considerazione la nuova pulsazione e ottengo così i valori di modulo e fase
%}
wc = 6.3;
[modulo,fase] = bode(L_iniziale,wc);
modulo
fase
margine_fase_iniziale = 180-abs(fase)

%{ 
Ottengo un valore del modulo maggiore di 1 e l'argomento negativo.
Avrò che il margine di fase iniziale, pari a 180-abs(argomento), 
sarà 45.7428° ovvero maggiore del margine di fase richiesto che è 39°. 
In aggiunta, poichè picco di risonanza e smorzamento sono 
inversamente proporzionali, per mantenerlo al di sotto dei 3 dB allora
il margine di fase deve essere al di sopra del valore critico e cioè
maggiore di 39°. 
Ho dunque bisogno di introdurre una rete correttrice detta "attenuatrice"
che, nell'intorno della pulsazione di attraversamento scelta attenua il
modulo mentre lascia intatta (o modifica di poco) la fase.
La rete attenuatrice opera ponendo sul diagramma delle frequenze della
funzione di anello un polo prima ed uno zero dopo nella regione di bassa
frequenza.

Tale rete è descritta da una funzione di trasferimento del tipo
    C_lead(s) = (1+s*tauz)/(1+s*taup) 
dove taup è la costante di tempo del polo e tauz è la costante di tempo
dello zero; entrambe devono essere maggiori di zero.
La rete dovrà dunque mantenere quasi inalterato il margine di fase.
Prendo dunque come riferimento per il progetto un angolo theta pari a -1.7428°
 %}
theta = 44 - margine_fase_iniziale;
theta

% La variabile m rappresenza l'attenuazione necessaria per far recuperare 
% il valore unitario della funzione di anello
m=1/modulo;
m

%{ 
Provo a costruirmi la rete corretrice e verifico in particolare il segno
dei due fattori tauz e taup
%}
[tauz,taup] = generica(wc,m,theta);
taup
tauz

%{
Ottengo due valori taup e tauz positivi per cui ho ottenuto una rette
corretrice corretta. 
Tuttavia, per verificare la correttezza della rete ottenuta, procedo a
graficare la nuova rete ottenuta tramite un'analisi detta ex-post.
In particolare, chiamo C_lead la f.d.t della rete anticipatrice da mettere 
in cascata prima con il controllore e poi con la funzione di trasferimento 
della rete di partenza.
%}

% Calcolo la funzione di trasferimento della rete anticipatrice
C_lead = (1+s*tauz)/(1+s*taup);
C_lead

% Calcolo la funzione della cascata fra f.d.t. della rete anticipatrice e
% il controllore
C_finale = series(C,C_lead);
C_finale

% Calcolo la funzione di anello finale che descrive la rete
L_finale = series(C_finale,G);
L_finale

%{
 Rappresento la funzione di anello finale ottenuta. Ho ottenuto che il
 sistema risulta essersi stabilizzato per il criterio di Bode.
%}
figure(2);
margin(L_finale);
grid;
legend;

%{
Rappresento sovrapposte le funzioni di anello iniziale e quella
compensata per evidenziarne le differenze.
%}

figure(3);
margin(L_finale);
hold on;
margin(L_iniziale);
legend;

%{
Tramite il comando feedback procedo a calcolare la funzione di
trasferimento della retroazione tramite la quale posso verificare
graficamente che il picco di risonanza è minore di 3 db
%}
T = feedback(L_finale,1);
T
figure(4);
bodemag(T);
grid;
legend;

%{
Oltre che ad una verifica grafica, posso ricorrere ad una verifica numerica
dei valori ricercati: tramite la funzione mag2db ottengo che il valore del 
picco di risonanza è 2.8756 db(dunque al di sotto di 3db) e tramite il
comando bandwidth ottengo che la pulsazione è pari a 11.6129, dunque
perfettamente in linea con la fascia richiesta fra 6 e 13 rad/sec
%}
picco_risonanza = mag2db(getPeakGain(T));
picco_risonanza

pulsazione_banda_passante = bandwidth(T);
pulsazione_banda_passante

