/*drop table RICHIESTEPRENLUSSO;
drop table POSSIEDETAXILUSSO;
drop table CORSEPRENOTATE;
drop table CORSENONPRENOTATE;
drop table PATENTI;
drop table AZIONIREVISIONE;
drop table REVISIONI;
drop table AZIONICORRETTIVE;
drop table TURNI;
drop table PRENOTAZIONELUSSO;
drop table PRENOTAZIONEACCESSIBILE;
drop table PRENOTAZIONESTANDARD;
drop table TAXILUSSO;
drop table TAXIACCESSIBILE;
drop table TAXISTANDARD;
drop table TAXI;
drop table CONVENZIONIAPPLICATE;
drop table ANONIMETELEFONICHE;
drop table NONANONIME;
drop table CONVENZIONICLIENTI;
drop table OPERATORI;
drop table AUTISTI;
drop table BUSTEPAGA;
drop table RESPONSABILI;
drop table RICARICHE;
drop table DIPENDENTI;
drop table OPTIONALS;
drop table PRENOTAZIONI;
drop table CONVENZIONI;
drop table CLIENTI;

drop sequence seq_IDcorsa;
drop sequence seq_IDrevisione;
drop sequence seq_IDazione;
drop sequence seq_MatricolaDipendente;
drop sequence seq_IDtaxi;
drop sequence seq_IDricarica;
drop sequence seq_IDoptional;
drop sequence seq_IDprenotazione;
drop sequence seq_IDcliente;
drop sequence seq_IDconvenzione;
*/
-- Sequenza per la tabella CORSENONPRENOTATE
CREATE SEQUENCE seq_IDcorsa
    START WITH 1
    INCREMENT BY 1
    MAXVALUE 9999999
    NOCYCLE;


-- Sequenza per la tabella REVISIONI
CREATE SEQUENCE seq_IDrevisione
    START WITH 1
    INCREMENT BY 1
    MAXVALUE 9999999
    NOCYCLE;

-- Sequenza per la tabella AZIONICORRETTIVE
CREATE SEQUENCE seq_IDazione
    START WITH 1
    INCREMENT BY 1
    MAXVALUE 9999999
    NOCYCLE;

-- Sequenza per la tabella TAXI
CREATE SEQUENCE seq_IDtaxi
    START WITH 1
    INCREMENT BY 1
    MAXVALUE 9999999
    NOCYCLE;

-- Sequenza per la tabella RICARICA
CREATE SEQUENCE seq_IDricarica
    START WITH 1
    INCREMENT BY 1
    MAXVALUE 9999999
    NOCYCLE;

-- Sequenza per la tabella DIPENDENTI
CREATE SEQUENCE seq_MatricolaDipendente
    START WITH 1
    INCREMENT BY 1
    MAXVALUE 9999999
    NOCYCLE;

-- Sequenza per la tabella OPTIONALS
CREATE SEQUENCE seq_IDoptional
    START WITH 1
    INCREMENT BY 1
    MAXVALUE 9999999
    NOCYCLE;

-- Sequenza per la tabella PRENOTAZIONI
CREATE SEQUENCE seq_IDprenotazione
    START WITH 1
    INCREMENT BY 1
    MAXVALUE 9999999
    NOCYCLE;

-- Sequenza per la tabella CONVENZIONI
CREATE SEQUENCE seq_IDconvenzione
    START WITH 1
    INCREMENT BY 1
    MAXVALUE 9999999
    NOCYCLE;

-- Sequenza per la tabella CLIENTI
CREATE SEQUENCE seq_IDcliente
    START WITH 1
    INCREMENT BY 1
    MAXVALUE 9999999
    NOCYCLE;


Create table CLIENTI
(
    IDcliente number(6) default seq_IDcliente.nextval primary key,
    Nome varchar2(20)  not null,
    Cognome varchar2(20) not null,
    DataNascita date not null,
    Sesso char(1) check(Sesso='M' or Sesso='F' or Sesso='N') not null,
    Ntelefono number(10) not null,
    Email varchar2(50) not null unique,
    Password varchar2(20) not null,
    Stato number(1) default 1 not null check (Stato IN(0,1)),
    Saldo number(4) default 0 check(Saldo>=0) not null
);

Create table CONVENZIONI
(
    IDconvenzione number(6) default seq_IDconvenzione.nextval primary key,
    Nome varchar2(100) unique not null,
    Ente varchar2(100) not null,
    Sconto number(2) not null check(Sconto>0),
    CodiceAccesso varchar2(40) unique not null,
    DataInizio date not null,
    DataFine date not null,
    Cumulabile NUMBER(1) not null CHECK (Cumulabile IN (0, 1)),
    check(DataFine>DataInizio)
);

Create table PRENOTAZIONI
(
    IDprenotazione number(6) default seq_IDprenotazione.nextval primary key,
    DataOra date not null,
    LuogoPartenza varchar2(100) not null,
    Npersone number(1) not null check(Npersone>0),
    LuogoArrivo varchar2(100) not null,
    Stato varchar2(9) not null check(Stato='accettata' or Stato='rifiutata' or Stato='pendente' or Stato='annullata'),
    Modificata NUMBER(1) default 0 not null CHECK (Modificata IN (0, 1)),
    Durata number(3) not null check(Durata>=0),
    check(LuogoPartenza<>LuogoArrivo)
);

Create table OPTIONALS
(
    IDoptionals number(6) default seq_IDoptional.nextval primary key,
    Nome varchar2(50) unique not null
);

Create table DIPENDENTI
(
    Matricola number(6) default seq_MatricolaDipendente.nextval primary key,
    Nome varchar2(20)  not null,
    Cognome varchar2(20) not null,
    DataNascita date not null,
    Sesso char(1) check(Sesso='M' or Sesso='F' or Sesso='N') not null,
    Ntelefono number(10) not null,
    Email varchar2(50) not null unique,
    Password varchar2(20) not null,
    Stato number(1) default 1 not null check (Stato IN(0,1)), 
    CF char(16) unique,
    Bonus number(3) default 0 check(Bonus>=0 and Bonus<=100),
    Indirizzo varchar2(100) not null,
    EmailAziendale varchar2(50) not null unique
);

Create table RICARICHE
(
    IDricarica number(6) default seq_IDricarica.nextval primary key,
    FK_Cliente number(6) references CLIENTI(IDcliente) on delete cascade,
    Data date not null,
    Importo number(4) not null check(Importo>0)
);

Create table RESPONSABILI
(
    FK_Dipendente number(6) primary key references DIPENDENTI(Matricola) on delete cascade,
    Ruolo number(1) not null check(Ruolo in (0,1))
);

Create table BUSTEPAGA
(
    FK_Dipendente number(6) not null references DIPENDENTI(Matricola),
    FK_Contabile number(6) not null references RESPONSABILI(FK_Dipendente),
    Data date not null,
    Importo number(4) not null check(Importo>0),
    Bonus number(4) default 0 not null check(Bonus>=0),
    primary key(FK_Dipendente, Data)
);

Create table AUTISTI 
(
    FK_Dipendente number(6) primary key references DIPENDENTI(Matricola) on delete cascade,
    DataPatente date not null
);

Create table OPERATORI
(
    FK_Dipendente number(6) primary key references DIPENDENTI(Matricola) on delete cascade
);

Create table CONVENZIONICLIENTI
(
    FK_Cliente number(6) not null references CLIENTI(IDcliente),
    FK_Convenzione number(6) not null references CONVENZIONI(IDconvenzione),
    primary key(FK_Cliente,FK_Convenzione)
);

Create table NONANONIME
(
    FK_Prenotazione number(6) primary key references PRENOTAZIONI(IDprenotazione),
    FK_Operatore number(6) references OPERATORI(FK_Dipendente),
    FK_Cliente number(6) not null references CLIENTI(IDcliente),
    Tipo number(1) not null check(Tipo in (0,1))
);

Create table ANONIMETELEFONICHE
(
    FK_Prenotazione number(6) primary key references PRENOTAZIONI(IDprenotazione),
    FK_Operatore number(6) not null references OPERATORI(FK_Dipendente),
    Ntelefono number(10) not null
);

Create table CONVENZIONIAPPLICATE
(
    FK_Convenzione number(6) not null references CONVENZIONI(IDconvenzione), 
    FK_NonAnonime number(6) not null references NONANONIME(FK_Prenotazione),
    primary key(FK_Convenzione,FK_NonAnonime)
);

Create table TAXI
(
    IDtaxi number(6) default seq_IDtaxi.nextval primary key,
    FK_Referente number(6) not null references AUTISTI(FK_Dipendente),
    Targa varchar2(7) not null unique,
    Cilindrata number(4) not null check(Cilindrata>0),
    Nposti number(1) not null check(Nposti>0),
    KM number(6) default 0 not null check(KM>=0),
    Stato varchar2(15) check(Stato='disponibile' or Stato='occupato' or Stato='prenotato' or Stato='non disponibile' or Stato='fermo'),
    Tariffa number(3,2) not null check (Tariffa>0)
);

Create table TAXISTANDARD
(
    FK_Taxi number(6) primary key references TAXI(IDtaxi)
);

Create table TAXIACCESSIBILE
(
    FK_Taxi number(6) primary key references TAXI(IDtaxi),
    NpersoneDisabili number(1) not null check(NpersoneDisabili>0)
);

Create table TAXILUSSO
(    
    FK_Taxi number(6) primary key references TAXI(IDtaxi)   
);

Create table PRENOTAZIONESTANDARD
(
    FK_Prenotazione number(6) primary key references PRENOTAZIONI(IDprenotazione),
    FK_Taxi number(6) references TAXISTANDARD(FK_Taxi)    
);

Create table PRENOTAZIONEACCESSIBILE
(
    FK_Prenotazione number(6) primary key references PRENOTAZIONI(IDprenotazione),
    FK_TaxiAccessibile number(6) references TAXIACCESSIBILE(FK_Taxi),
    NpersoneDisabili number(1) not null check(NpersoneDisabili>0)  
);

Create table PRENOTAZIONELUSSO
(
    FK_Prenotazione number(6) primary key references PRENOTAZIONI(IDprenotazione),
    FK_Taxi number(6) references TAXILUSSO(FK_Taxi)
);

CREATE TABLE TURNI
(
    FK_Manager NUMBER(6) NOT NULL REFERENCES RESPONSABILI(FK_Dipendente),
    FK_Autista NUMBER(6) NOT NULL REFERENCES AUTISTI(FK_Dipendente),
    FK_Taxi NUMBER(6) NOT NULL REFERENCES TAXI(IDtaxi),
    DataOraInizio DATE NOT NULL,
    DataOraFine DATE NOT NULL,
    DataOraInizioEff DATE,
    DataOraFineEff DATE,
    PRIMARY KEY (FK_Autista, FK_Taxi, DataOraInizio),
    check(DataOraInizio < DataOraFine),
    check(DataOraInizioEff < DataOraFineEff),
    check(DataOraInizioEff >= DataOraInizio and DataOraInizioEff < DataOraFine),
    check(DataOraFineEff> DataOraInizioEff and DataOraFineEff <= DataOraFine + INTERVAL '2' HOUR)
);

CREATE TABLE AZIONICORRETTIVE
(
    IDazione NUMBER(6) default seq_IDazione.nextval PRIMARY KEY,
    Azione VARCHAR2(100) NOT NULL
);

CREATE TABLE REVISIONI
(
    IDrevisione NUMBER(6) default seq_IDrevisione.nextval PRIMARY KEY,
    FK_Taxi NUMBER(6) NOT NULL REFERENCES TAXI(IDtaxi),
    DataOra DATE NOT NULL,
    Risultato NUMBER(1) NOT NULL check(Risultato in (0,1)),
    Scadenza DATE
);

CREATE TABLE AZIONIREVISIONE
(
    FK_Azione NUMBER(6) NOT NULL REFERENCES AZIONICORRETTIVE(IDazione),
    FK_Revisione NUMBER(6) NOT NULL REFERENCES REVISIONI(IDrevisione),
    PRIMARY KEY (FK_Azione, FK_Revisione)
);

CREATE TABLE PATENTI
(
    FK_Autista NUMBER(6) NOT NULL REFERENCES  AUTISTI(FK_Dipendente),
    Codice VARCHAR2(10) PRIMARY KEY,
    Scadenza DATE NOT NULL,
    Rilascio DATE NOT NULL,
    Validita NUMBER(1) default 1 NOT NULL CHECK (Validita IN (0, 1)),
    check(Rilascio < Scadenza)
);

CREATE TABLE CORSENONPRENOTATE
(
    IDcorsa NUMBER(6) default seq_IDcorsa.nextval PRIMARY KEY,
    DataOra DATE NOT NULL,
    Durata NUMBER(3),
    Importo NUMBER(5,2),
    Passeggeri NUMBER(1) NOT NULL,
    KM NUMBER(3),
    Partenza VARCHAR2(100) NOT NULL,
    Arrivo VARCHAR2(100),
    FK_Standard NUMBER(6) NOT NULL REFERENCES TAXISTANDARD(FK_Taxi),
    check(Partenza<>Arrivo)
);

CREATE TABLE CORSEPRENOTATE
(
    FK_Prenotazione NUMBER(6) PRIMARY KEY REFERENCES PRENOTAZIONI(IDprenotazione),
    DataOra DATE NOT NULL,
    Durata NUMBER(3) ,
    Importo NUMBER(5,2),
    Passeggeri NUMBER(1) NOT NULL,
    KM NUMBER(3)
);

CREATE TABLE POSSIEDETAXILUSSO
(
    FK_TaxiLusso NUMBER(6) NOT NULL REFERENCES TAXILUSSO(FK_Taxi),
    FK_Optionals NUMBER(6) NOT NULL REFERENCES OPTIONALS(IDoptionals),
    PRIMARY KEY (FK_TaxiLusso, FK_Optionals)
);

CREATE TABLE RICHIESTEPRENLUSSO
(
    FK_Prenotazione NUMBER(6) NOT NULL REFERENCES PRENOTAZIONI(IDprenotazione),
    FK_Optionals NUMBER(6) NOT NULL REFERENCES OPTIONALS(IDoptionals),
    PRIMARY KEY (FK_Prenotazione, FK_Optionals)
);
