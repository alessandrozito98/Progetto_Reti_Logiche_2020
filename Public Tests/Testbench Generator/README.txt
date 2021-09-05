## Istruzioni generatore
Il file `generatore.c` contiene il codice del generatore di test. Questo, unito al file `multipleTests.vhd` descritto più avanti, può essere usato per generare un gran numero di test per il modulo.

Una volta lanciato il programma si potrà scegliere tra tre opzioni per la generazione del test:
- Test generati in modo casuale
- Test generati a partire da un file
- Test generati a partire dall'inserimento dei dati via console


### 1. Test casuali
Il programma chiede i parametri che si vogliono utilizzare per la generazione dei test.

**NOTA**: i parametri vengono scelti una volta per ogni esecuzione del programma e sono utilizzati per tutti i test che vengono generati in quella sessione.
I valori da inserire sono:

* `minRighe` e `maxRighe` - Entrambi valori tra 0 e 128. Il numero di righe di ogni test generato sarà compreso nel range specificato. Inserire `minRighe`=`maxRighe` permette di fissare le righe dei test ad un unico valore.

* `minColonne` e `maxColonne` - Entrambi valori tra 0 e 128. Il numero di colonne di ogni test generato sarà compreso nel range specificato. Inserire `minColonne`=`maxColonne` permette di fissare le colonne dei test ad un unico valore.

* `minPixel` e `maxPixel` - Entrambi compresi tra 0 e 255. Tutti i pixel presenti nei test avranno un intervallo compreso nel range. Inserire `minPixel`=`maxPixel` produce matrici con tutti i pixel allo stesso valore.

Dopo aver inserito i parametri verrà chiesto il numero di test da generare. Con alcune prove si è visto che le dimensioni dei file creati dal generatore aumentano notevolmente con l'aumentare dei test. Per questo motivo se si desidera creare più di 10000 test il programma offrirà l'opzione di spezzare l'output in più file. In ogni caso tutti test iniziano e finiscono nello stesso file.


### 2. Test da file
Il programma chiede il percorso a cui trovare il file da cui generare i test.

Il file deve rispettare la seguente struttura (senza lasciare righe vuote all'inizio del file):

    nome primo test
    3-4
      1 168  34   7
    100  78   6 255
     21   4 123  50
    nome secondo test
    2-2
    120  30
      5   9

**Nota**: le colonne delle matrici sono allineate a destra con numeri di 3 cifre.


### 3. Test da console
Il programma chiede il nome da dare al test e le dimensioni della matrice da generare.  
Viene poi chiesto di inserire la matrice del test riga per riga. I numeri che compongono la riga devono essere separati da uno spazio.



### Output
Una volta generati tutti i test il programma termina. Nella cartella del programma saranno stati creati 3 file (o più nel caso di output diviso su più file):
* `ramDataX.txt` : contiene i dati che veranno caricati nella RAM per l'esecuzione di ogni test
* `ramResultX.txt` : contiene i dati della soluzione di ogni test. Il contenuto di questo file verrà confrontato con il contenuto della RAM alla fine di ogni test per verificare la correttezza del risultato.
* `testX.txt` : contiene una versione più leggibile dei test generati.






## ISTRUZIONI TEST BENCH VHDL
Per utiliazzare il file `multipleTests.vhd` è necessario modificare le linee 68 e 108 inserendo i percorsi rispettivamente al file `ramData.txt` e `ramResult.txt` prodotti dal generatore (es: `path/to/ramData.txt`).  
Bisogna inoltre modificare il percorso alla linea 109. Questo deve essere il percorso di un file di testo (non necessariamente esistente) in cui verrano segnalati i test che non sono stati passati (es: `path/to/NotPassed.txt`).  
A questo punto il test è pronto per essere lanciato. Si tenga presente che questo test manda il segnale di reset del modulo prima dell'esecuzione del primo test e poi suppone che sia il modulo stesso a riportarsi nella condizione di eseguire un'altra conversione.

### Output
Il test bench genera un file `.txt` in output al percorso inserito alla linea 109. In questo file sono segnalati tutti pixel che sono risultati sbagliati dopo la conversione indicando il test da cui provengono e il numero del pixel relativo all'interno del test. Vengono scritti sia il valore corretto che quello effettivamente stampato dal modulo.

Esempio di contenuto di del file di output:

    TEST 5: pixel 4 expected 100 found 204