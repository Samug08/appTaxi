--SET DEFINE OFF;
create or replace PACKAGE BODY Gruppo4 as


--Michele
procedure StatisticheAutisti(
    IDSessione varchar2 default null,
    Errmsg varchar2 default null,
    MatricolaI Dipendenti.Matricola%TYPE default null,
    NomeI Dipendenti.Nome%TYPE default null,
    CognomeI Dipendenti.Cognome%TYPE default null,
    DataInI varchar2 default TO_CHAR(SYSDATE,'YYYY-MM-DD'),
    DataFinI varchar2 default TO_CHAR(SYSDATE,'YYYY-MM-DD')
)AS
    inizio DATE;
    fine DATE;
    temp DATE;
    nomeT varchar2(20):=null;
    cognomeT varchar2(20):=null;
    matricolaT number:=MatricolaI;
begin    
    gui.ApriPagina('Statistiche autisti',IDSessione);

    if(Errmsg is not null)then 
        gui.AggiungiPopup(false, Errmsg);
    end if;

    if SessionHandler.getRuolo(IDSessione) <> 'Manager' and SessionHandler.getRuolo(IDSessione) <> 'Autista' THEN
        gui.AggiungiPopup(true, 'Non hai il permesso per visualizzare questa pagina!');
        gui.acapo(3);
        gui.bottoneaggiungi(testo => 'Ritorna alla home', url =>costanti.URL ||'gui.homepage?idSessione='||IDSessione||chr(38)||'p_success=S');
        --gui.reindizza(HOMEPAGE)
        gui.chiudipagina;
        return;
    end if;

    if SessionHandler.getRuolo(IDSessione) = 'Autista' then
        matricolaT:=SessionHandler.GETIDUSER(IDSessione);
    end if;

    if NomeI is not null then
        nomeT:=LOWER(TRIM(NomeI)); 
    end if;

    if CognomeI is not null then
        cognomeT:=LOWER(TRIM(cognomeI)); 
    end if;


    inizio:=TO_DATE(DataInI,'YYYY-MM-DD');
    fine:=TO_DATE(DataFinI,'YYYY-MM-DD');

    if(fine<inizio)then
        temp:=inizio;
        inizio:=fine;
        fine:=temp;
    end if;

    fine:=fine + (INTERVAL '1' DAY) - (INTERVAL '1' SECOND);



    gui.AGGIUNGIINTESTAZIONE('Statistiche autisti');
    gui.ACAPO;

    gui.ApriFormFiltro(URL||'StatisticheAutisti');
    gui.AGGIUNGICAMPOFORMFILTRO(tipo=>'date',nome => 'DataInI', value=>TO_CHAR(inizio,'YYYY-MM-DD'), placeholder=>'Data inizio');
    gui.AGGIUNGICAMPOFORMFILTRO(tipo=>'date',nome => 'DataFinI', value=>TO_CHAR(fine,'YYYY-MM-DD'), placeholder=>'Data fine');
    gui.AGGIUNGICAMPOFORMFILTRO(tipo=>'number',nome => 'MatricolaI',value=>matricolaT,placeholder=>'Matricola');
    gui.AGGIUNGICAMPOFORMFILTRO(nome => 'NomeI',value=>NomeI,placeholder=>'Nome');
    gui.AGGIUNGICAMPOFORMFILTRO(nome => 'CognomeI',value=>CognomeI,placeholder=>'Cognome');
    gui.aggiungicampoformhidden(nome => 'IDSessione', value => IDSessione);
    gui.AggiungiCampoFormFiltro('submit', '', '', 'Filtra');
    gui.ChiudiFormFiltro();
    gui.ACAPO(3);

    gui.AGGIUNGIINTESTAZIONE('Stai visualizzando i dati dal '||TO_CHAR(inizio,'DD/MM/YYYY')||' al '||TO_CHAR(fine,'DD/MM/YYYY'));
    gui.ACAPO;

    gui.APRITABELLA(gui.StringArray('Matricola','Nome','Cognome','Ore di Lavoro ','Straordinari','Numero Turni','Ore medie per turno','Ritardo Medio','Somma Ritardi'));
    for stat in(
        SELECT 
            dip.MATRICOLA, dip.NOME, dip.Cognome, 
            ore.TotaleOre, ore.numeroTurni, 
            ritardo.ritardoMedio, ritardo.sommaRitardi
        FROM 
            Dipendenti dip left outer join
            ( 
                --Ore totali effettuate e numero turni
                SELECT 
                    MATRICOLA,
                    SUM(Durata)*24 as TotaleOre,
                    COUNT(*) as numeroTurni
                FROM 
                    (
                    SELECT 
                        A.FK_DIPENDENTE AS MATRICOLA,
                        (T.DATAORAFINEEFF-T.DATAORAINIZIOEFF) as Durata
                    FROM 
                        AUTISTI A JOIN TURNI T ON A.FK_DIPENDENTE=T.FK_AUTISTA
                    WHERE 
                        T.DATAORAFINEEFF is not null and T.DATAORAINIZIOEFF is not null
                        AND T.DATAORAINIZIO>=inizio AND T.DATAORAINIZIO<=fine
                    )
                GROUP BY MATRICOLA
            ) ore on dip.MATRICOLA =ore.MATRICOLA left outer join(
                --ritardi
                SELECT 
                    T.FK_Autista AS Matricola, 
                    AVG(T.DATAORAINIZIOEFF-T.DATAORAINIZIO)*24*60 as ritardoMedio, 
                    SUM(T.DATAORAINIZIOEFF-T.DATAORAINIZIO)*24*60 as sommaRitardi
                FROM TURNI T 
                WHERE 
                    T.DATAORAFINEEFF is not null and T.DATAORAINIZIOEFF is not null
                    AND T.DATAORAINIZIO>=inizio AND T.DATAORAINIZIO<=fine
                    AND T.DATAORAINIZIO>=
                        (
                            SELECT MAX(Tu.DATAORAFINEEFF)
                            FROM TURNI Tu join Taxi Ta on Tu.FK_Taxi=Ta.IDtaxi
                            WHERE 
                                T.FK_Taxi=Ta.IDtaxi and
                                Tu.DATAORAINIZIO<T.DATAORAINIZIO
                        )
                GROUP BY T.FK_Autista
            ) ritardo on ore.Matricola=ritardo.Matricola
        WHERE 
            (MatricolaT is null or Dip.Matricola=MatricolaT) and
            (nomeT is null or LOWER(Dip.Nome) like '%'||nomeT||'%') and
            (cognomeT is null or LOWER(Dip.Cognome) like '%'||cognomeT||'%') 
        ORDER BY ore.MATRICOLA
    )LOOP
        gui.AGGIUNGIRIGATABELLA;
            gui.AGGIUNGIELEMENTOTABELLA(stat.Matricola);
            gui.AGGIUNGIELEMENTOTABELLA(stat.Nome);
            gui.AGGIUNGIELEMENTOTABELLA(stat.Cognome);
            IF stat.TotaleOre is not null and stat.numeroTurni is not null THEN

                gui.AGGIUNGIELEMENTOTABELLA(TRUNC(stat.TotaleOre)||'H '||TRUNC((stat.TotaleOre-FLOOR(stat.TotaleOre))*60)||'m');
                if(stat.TotaleOre>((fine-inizio)*40/7))
                THEN
                    gui.AGGIUNGIELEMENTOTABELLA((TRUNC(stat.TotaleOre-((fine-inizio)*40/7)))||'H '||(TRUNC((stat.TotaleOre-((fine-inizio)*40/7))-(FLOOR(stat.TotaleOre-((fine-inizio)*40/7))))*60)||'m');
                ELSE
                    gui.AGGIUNGIELEMENTOTABELLA('0H 0m');
                END IF;
                gui.AGGIUNGIELEMENTOTABELLA(stat.numeroTurni);
                gui.AGGIUNGIELEMENTOTABELLA(TRUNC(stat.TotaleOre/stat.numeroTurni)||'H '||TRUNC((stat.TotaleOre/stat.numeroTurni-FLOOR(stat.TotaleOre/stat.numeroTurni))*60)||'m');

            ELSE
                gui.AGGIUNGIELEMENTOTABELLA('0H 0m');
                gui.AGGIUNGIELEMENTOTABELLA('0H 0m');
                gui.AGGIUNGIELEMENTOTABELLA('0');
                gui.AGGIUNGIELEMENTOTABELLA('0H 0m');
            END IF;

            IF stat.RitardoMedio is not null and stat.SommaRitardi is not null THEN            
                gui.AGGIUNGIELEMENTOTABELLA(TRUNC(stat.RitardoMedio)||'m '||TRUNC((stat.RitardoMedio-FLOOR(stat.RitardoMedio))*60)||'s');
                gui.AGGIUNGIELEMENTOTABELLA(TRUNC(stat.SommaRitardi)||'m '||TRUNC((stat.SommaRitardi-FLOOR(stat.SommaRitardi))*60)||'s');
            ELSE
                gui.AGGIUNGIELEMENTOTABELLA('0m 0s');
                gui.AGGIUNGIELEMENTOTABELLA('0m 0s');
            END IF;
        gui.ChiudiRigaTabella;
    END LOOP;
    
    gui.CHIUDITABELLA;
    gui.ACAPO(3);

    gui.chiudiPagina;

    EXCEPTION 
        WHEN OTHERS THEN
            gui.reindirizza(URL||'StatisticheAutisti?IDSessione='||IDSessione||chr(38)||'Errmsg='||SQLERRM);
END StatisticheAutisti;

procedure CoperturaTurni(
    IDSessione varchar2 default null,
    Errmsg varchar2 default null,
    DataInI varchar2 default TO_CHAR(SYSDATE,'YYYY-MM-DD'),
    DataFinI varchar2 default TO_CHAR(SYSDATE,'YYYY-MM-DD')
)AS
    inizio DATE;
    fine DATE;
    temp DATE;
    inFasce gui.StringArray := gui.StringArray();
    durataFascia number:=3;
    oreFascia number;
    totTurni number:=0;
begin   
    gui.ApriPagina('Copertura turni',IDSessione);

    if(Errmsg is not null)then 
        gui.AggiungiPopup(false, Errmsg);
        return;
    end if;

    if SessionHandler.getRuolo(IDSessione) <> 'Manager' THEN
        gui.AggiungiPopup(true, 'Non hai il permesso per visualizzare questa pagina!');
        gui.acapo(3);
        gui.bottoneaggiungi(testo => 'Ritorna alla home', url =>costanti.URL ||'gui.homepage?idSessione='||IDSessione||chr(38)||'p_success=S');
        --gui.reindizza(HOMEPAGE)
        gui.chiudipagina;
        return;
    end if;

    inFasce := gui.StringArray('00:00:00','03:00:00','06:00:00','09:00:00','12:00:00','15:00:00','18:00:00','21:00:00');           

    inizio:=TO_DATE(DataInI,'YYYY-MM-DD');
    fine:=TO_DATE(DataFinI,'YYYY-MM-DD');

    if(fine<inizio)then
        temp:=inizio;
        inizio:=fine;
        fine:=temp;
    end if;

    fine:=fine + (INTERVAL '1' DAY) - (INTERVAL '1' SECOND);

    gui.AGGIUNGIINTESTAZIONE('Copertura Turni');
    gui.ACAPO;

    gui.ApriFormFiltro(URL||'CoperturaTurni');
    gui.AGGIUNGICAMPOFORMFILTRO(tipo=>'date',nome => 'DataInI', value=>TO_CHAR(inizio,'YYYY-MM-DD'), placeholder=>'Data inizio');
    gui.AGGIUNGICAMPOFORMFILTRO(tipo=>'date',nome => 'DataFinI', value=>TO_CHAR(fine,'YYYY-MM-DD'), placeholder=>'Data fine');
    gui.aggiungicampoformhidden(nome => 'IDSessione', value => IDSessione);
    gui.AggiungiCampoFormFiltro('submit', '', '', 'Filtra');
    gui.ChiudiFormFiltro();
    gui.ACAPO(3);

    gui.AGGIUNGIINTESTAZIONE('Stai visualizzando i dati dal '||TO_CHAR(inizio,'DD/MM/YYYY')||' al '||TO_CHAR(fine,'DD/MM/YYYY'));
    gui.ACAPO;

    gui.APRITABELLA(gui.StringArray('Fascia','Totale ore','Totale turni','Media autisti diponibili'));
    FOR i in 1..inFasce.count LOOP
        oreFascia:=0;
        totTurni:=0;
        FOR turno in(
            SELECT T.DATAORAINIZIO,T.DATAORAFINE
            FROM TURNI T 
            WHERE 
                T.DATAORAINIZIO BETWEEN inizio and fine or
                T.DATAORAFINE BETWEEN inizio and fine 
        ) LOOP
            --inizia e finisce nella fascia
            if
                turno.DATAORAINIZIO BETWEEN toSameDay(turno.DATAORAINIZIO,inFasce(i)) and (toSameDay(turno.DATAORAINIZIO,inFasce(i))+durataFascia/24) and
                turno.DATAORAFINE BETWEEN toSameDay(turno.DATAORAINIZIO,inFasce(i)) and (toSameDay(turno.DATAORAINIZIO,inFasce(i))+durataFascia/24)
            then
                oreFascia:=oreFascia+turno.DATAORAFINE-turno.DATAORAINIZIO;
                totTurni:=totTurni+1;
            --inizia nella fascia
            elsif
                turno.DATAORAINIZIO BETWEEN toSameDay(turno.DATAORAINIZIO,inFasce(i)) and (toSameDay(turno.DATAORAINIZIO,inFasce(i))+durataFascia/24) and
                turno.DATAORAFINE>=toSameDay(turno.DATAORAINIZIO,inFasce(i))
            then
                oreFascia:=oreFascia+(toSameDay(turno.DATAORAINIZIO,inFasce(i))+durataFascia/24)-turno.DATAORAINIZIO;
                totTurni:=totTurni+1;
            --finisce nella fascia
            elsif
                turno.DATAORAFINE BETWEEN toSameDay(turno.DATAORAFINE,inFasce(i)) and (toSameDay(turno.DATAORAFINE,inFasce(i))+durataFascia/24) and
                turno.DATAORAINIZIO<=toSameDay(turno.DATAORAFINE,inFasce(i))
            then
                oreFascia:=oreFascia+turno.DATAORAFINE-toSameDay(turno.DATAORAFINE,inFasce(i));
                totTurni:=totTurni+1;
            --inizia e finisce fuori dalla fascia
            elsif
                turno.DATAORAINIZIO<=toSameDay(turno.DATAORAINIZIO,inFasce(i)) and
                turno.DATAORAFINE>=(toSameDay(turno.DATAORAINIZIO,inFasce(i))+durataFascia/24)
            then
                oreFascia:=oreFascia+durataFascia/24;
                totTurni:=totTurni+1;
            end if;
            
        END LOOP;
        
        gui.AGGIUNGIRIGATABELLA;
        if(i=inFasce.count) then 
            gui.AGGIUNGIELEMENTOTABELLA(inFasce(i)||'-'||inFasce(1));
        else 
            gui.AGGIUNGIELEMENTOTABELLA(inFasce(i)||'-'||inFasce(i+1));
        end if;
        
        gui.AGGIUNGIELEMENTOTABELLA(TRUNC(oreFascia*24)||'H '||TRUNC(((oreFascia*24)-TRUNC(oreFascia*24))*24*60)||'m');
        gui.AGGIUNGIELEMENTOTABELLA(totTurni);
        gui.AGGIUNGIELEMENTOTABELLA(TRUNC((oreFascia*24/(durataFascia*(trunc(fine-inizio)+1))),2));
        gui.ChiudiRigaTabella;

    END LOOP;

    gui.CHIUDITABELLA;
    gui.ACAPO(3);

    gui.chiudiPagina;
    EXCEPTION 
        WHEN OTHERS THEN
            gui.reindirizza(URL||'CoperturaTurni?IDSessione='||IDSessione||chr(38)||'Errmsg='||SQLERRM);
END CoperturaTurni;

function toSameDay(
    data Date,
    ora varchar2
) return DATE
IS
BEGIN
    return TO_DATE(TO_CHAR(data,'YYYY-MM-DD')||' '||ora,'YYYY-MM-DD HH24:mi:ss');
END toSameDay;

procedure visualizzazionePatenti(
    MatricolaI in Dipendenti.Matricola%TYPE default null,
    NomeI Dipendenti.Nome%TYPE default null,
    CognomeI Dipendenti.Cognome%TYPE default null,
    ValiditaI number default null,
    DataInI varchar2 default null,
    DataFinI varchar2 default null,
    idSessione varchar2 default null,
    msg varchar2 default null,
    err number default null
)IS
    matricolaT number:=MatricolaI;
    nomeT varchar2(20):=null;
    cognomeT varchar2(20):=null;
    ValiditaT number:=ValiditaI;
    inizio DATE:=null;
    fine DATE:=null;
    temp DATE;
    ruolo varchar2(20);
BEGIN

    gui.APRIPAGINA('Visualizza Patenti', idSessione);

    if(msg is not null)then 
        if(err=0)then
            gui.AggiungiPopup(true, msg);
        else
            gui.AggiungiPopup(false, msg);
        end if;
    end if;

    ruolo := SessionHandler.getRuolo(idSessione);

    IF ruolo<>'Manager' AND ruolo<>'Autista' THEN
        gui.AggiungiPopup(false, 'Non hai il permesso per visualizzare questa pagina!');
        gui.acapo(3);
        gui.bottoneaggiungi(testo => 'Ritorna alla home', url =>costanti.URL ||'gui.homepage?idSessione='||IDSessione||chr(38)||'p_success=S');
        gui.chiudipagina;
        return;
    END IF;

    IF ruolo = 'Autista' THEN
        matricolaT:=SessionHandler.getIDuser(idSessione);
    END IF;

    IF ValiditaI is null THEN 
        ValiditaT:=1;
    END IF;

    IF DataInI is not null and DataFinI is not null THEN
        inizio:=TO_DATE(DataInI,'YYYY-MM-DD');
        fine:=TO_DATE(DataFinI,'YYYY-MM-DD');

        if(fine<inizio)then
            temp:=inizio;
            inizio:=fine;
            fine:=temp;
        end if;

        fine:=fine + (INTERVAL '1' DAY) - (INTERVAL '1' SECOND);
    END IF;

    if NomeI is not null then
        nomeT:=LOWER(TRIM(NomeI)); 
    end if;

    if CognomeI is not null then
        cognomeT:=LOWER(TRIM(cognomeI)); 
    end if;

    gui.AGGIUNGIINTESTAZIONE('Visualizzazione patenti');

    gui.ACAPO;

    gui.ApriFormFiltro(URL||'visualizzazionePatenti');
    gui.AGGIUNGICAMPOFORMFILTRO(tipo=>'number',nome => 'MatricolaI',value=>matricolaT,placeholder=>'Matricola');

    gui.AGGIUNGICAMPOFORMFILTRO(nome => 'NomeI',value=>NomeI,placeholder=>'Nome');
    gui.AGGIUNGICAMPOFORMFILTRO(nome => 'CognomeI',value=>CognomeI,placeholder=>'Cognome');

    gui.ApriSelectFormFiltro(nome=>'ValiditaI', placeholder=>'Validità',firstNull=>false);
    gui.aggiungiOpzioneselect('-1', ValiditaT=-1, 'Entrambe');
    gui.aggiungiOpzioneselect('1', ValiditaT=1, 'Valida');
    gui.aggiungiOpzioneselect('0', ValiditaT=0, 'Non valida');
    gui.chiudiSelectFormFiltro;

    gui.AGGIUNGICAMPOFORMFILTRO(tipo=>'date',nome => 'DataInI', value=>TO_CHAR(inizio,'YYYY-MM-DD'), placeholder=>'Data inizio scadenza');
    gui.AGGIUNGICAMPOFORMFILTRO(tipo=>'date',nome => 'DataFinI', value=>TO_CHAR(fine,'YYYY-MM-DD'), placeholder=>'Data fine scadenza');

    gui.aggiungicampoformhidden(nome => 'IDSessione', value => IDSessione);
    gui.AggiungiCampoFormFiltro('submit', '', '', 'Filtra');
    gui.ChiudiFormFiltro();

    gui.ACAPO(3);

    IF ruolo = 'Manager' THEN
        gui.bottoneaggiungi(testo=>'Inserisci Patente', url=> URL || 'inserimentoPatente?idSessione=' || idSessione);
        gui.apritabella(gui.stringarray('Matricola autista','Nome','Cognome','Codice', 'Rilascio', 'Scadenza', 'Validità', ' '));
    ELSE
        gui.apritabella(gui.stringarray('Matricola autista','Nome','Cognome','Codice', 'Rilascio', 'Scadenza', 'Validità'));
    END IF;

    FOR Patente IN(
        SELECT 
            d.Matricola as Matricola,
            d.Nome as Nome,
            d.Cognome as Cognome,
            p.Codice as Codice,
            p.Rilascio as Rilascio,
            p.Scadenza as Scadenza,
            p.Validita as Validita
        FROM 
            PATENTI p join AUTISTI a on p.FK_Autista=a.FK_Dipendente
            join DIPENDENTI d on p.FK_Autista=d.Matricola
        WHERE 
            (matricolaT is null or d.Matricola=matricolaT) and
            (ValiditaT=-1 or p.Validita=ValiditaT) and
            ((inizio is null and fine is null) or p.Scadenza between inizio and fine) and
            (nomeT is null or LOWER(d.Nome) like '%'||nomeT||'%') and
            (cognomeT is null or LOWER(d.Cognome) like '%'||cognomeT||'%') 
        ORDER BY FK_Autista
    )LOOP

        gui.AGGIUNGIRIGATABELLA;
        gui.AGGIUNGIELEMENTOTABELLA(Patente.Matricola);
        gui.AGGIUNGIELEMENTOTABELLA(Patente.Nome);
        gui.AGGIUNGIELEMENTOTABELLA(Patente.Cognome);
        gui.AGGIUNGIELEMENTOTABELLA(Patente.Codice);
        gui.AGGIUNGIELEMENTOTABELLA(TO_CHAR(Patente.Rilascio,'DD/MM/YYYY'));
        gui.AGGIUNGIELEMENTOTABELLA(TO_CHAR(Patente.Scadenza,'DD/MM/YYYY'));
        IF Patente.Validita=1 THEN
            gui.AGGIUNGIELEMENTOTABELLA('Valida');
        ELSE
            gui.AGGIUNGIELEMENTOTABELLA('Non valida');
        END IF;

        IF ruolo = 'Manager' THEN
            gui.aprielementopulsanti;
                        gui.AggiungiPulsanteModifica(URL || 'modificaPatente?' 
                                                                || 'CodOld=' || Patente.Codice || chr(38) 
                                                                ||'idSessione=' || idSessione);
                        IF Patente.Validita=1 THEN
                            gui.AGGIUNGIPULSANTEGENERALE(''''|| URL|| 'invalidaPatente?' 
                                                                        ||'idSessione=' || idSessione|| chr(38)
                                                                        || 'CodI=' || Patente.Codice||'''','Invalida');
                        END IF;
            gui.chiudielementopulsanti;
        END IF;
    END LOOP;

    gui.chiuditabella;

    gui.acapo(3);
    gui.CHIUDIPAGINA;

    EXCEPTION 
        WHEN OTHERS THEN
            gui.reindirizza(URL||'visualizzazionePatenti?IDSessione='||IDSessione||chr(38)||'msg='||SQLERRM||chr(38)||'err=1');
            return;

END visualizzazionePatenti;

procedure inserimentoPatente(
    MatricolaI in Dipendenti.Matricola%TYPE default null,
    CodI in patenti.Codice%TYPE default null,
    RilascioI varchar2 default null,
    ScadenzaI varchar2 default null,
    ValiditaI number default null,
    idSessione varchar2 default null,
    msg varchar2 default null,
    err number default null
)IS
    ruolo varchar2(20);
    elementi gui.Stringarray:=gui.Stringarray();
    reali gui.Stringarray:=gui.Stringarray();
    numero number(20);
BEGIN

    gui.apripagina('Inserimento patente', idSessione);

    if(msg is not null)then 
        if(err=0)then
            gui.AggiungiPopup(true, msg);
        else
            gui.AggiungiPopup(false, msg);
        end if;
    end if;

    ruolo := SessionHandler.getRuolo(idSessione);

    IF ruolo <> 'Manager'
    THEN
        gui.REINDIRIZZA(URL||'visualizzazionePatenti?idSessione='||idSessione||chr(38)||'msg=Non hai i permessi necessari'||chr(38)||'err=1');
    END IF;

    --aggiungere che autocompila i parametri in caso di errore

    IF MatricolaI IS NULL OR CodI IS NULL OR ScadenzaI IS NULL OR RilascioI IS NULL OR ValiditaI IS NULL
    THEN
        FOR autista in(
            SELECT d.Matricola,d.Nome,d.Cognome
            FROM DIPENDENTI d join AUTISTI a on d.Matricola=a.FK_DIPENDENTE
        )LOOP
            elementi.EXTEND;
            reali.EXTEND;
            elementi(elementi.LAST) := (autista.Matricola||' '||autista.Nome||' '||autista.Cognome);          
            reali(reali.LAST) := (autista.Matricola);
        END LOOP;


        gui.AGGIUNGIFORM(url => URL || 'inserimentoPatente');
        gui.aggiungiintestazione('Inserimento patente');

            gui.aggiungigruppoinput;
                gui.AGGIUNGISELEZIONESINGOLA(elementi => elementi, valoreEffettivo=>reali, titolo => 'Autista', ident => 'MatricolaI',optionSelected=>'MatricolaI');
                gui.AGGIUNGILABEL(target =>'CodI', testo =>'Codice patente');
                gui.AGGIUNGICAMPOFORM(nome => 'CodI', value => CodI, classeicona=>'fa fa-id-card');
            gui.chiudigruppoinput;
            gui.aggiungigruppoinput;
                gui.apridiv(classe=>'col-half');
                gui.AGGIUNGILABEL(target =>'RilascioI', testo =>'Data di rilascio');
                gui.AGGIUNGICAMPOFORM(tipo => 'date', nome => 'RilascioI', value => RilascioI, classeicona=>'fa fa-calendar');
                gui.chiudidiv;
                gui.apridiv(classe=>'col-half');
                gui.AGGIUNGILABEL(target =>'ScadenzaI', testo =>'Data di scadenza');
                gui.AGGIUNGICAMPOFORM(tipo => 'date', nome => 'ScadenzaI', value => ScadenzaI, classeicona=>'fa fa-calendar');
                gui.chiudidiv;
            gui.chiudigruppoinput;

            gui.aggiungigruppoinput;
                gui.AGGIUNGISELEZIONESINGOLA(elementi => gui.Stringarray('Valida', 'Non Valida'), valoreEffettivo=>gui.Stringarray('1', '0'), titolo => 'Validità', ident => 'ValiditaI',firstNull=>false);
            gui.chiudigruppoinput;

            gui.AggiungiCampoFormHidden(nome => 'idSessione', value => idSessione);

            gui.AGGIUNGIBOTTONESUBMIT(value=>'Inserisci');
        gui.chiudiform;
 
    ELSE

        IF to_date(ScadenzaI, 'yyyy-mm-dd') < to_date(RilascioI, 'yyyy-mm-dd') THEN
            gui.REINDIRIZZA(URL||'inserimentoPatente?IDSessione='||IDSessione||chr(38)||'msg=Errore: La data di scadenza precede quella di rilascio'||chr(38)||'err=1');
            return;
        END IF;

        SELECT COUNT(*) 
        INTO numero
        FROM Autisti 
        WHERE MatricolaI=FK_Dipendente;

        IF 1 <> numero THEN
            gui.REINDIRIZZA(URL||'inserimentoPatente?IDSessione='||IDSessione||chr(38)||'msg=Errore: L''autista non esiste'||chr(38)||'err=1');
            return;
        END IF;

        INSERT
        INTO Patenti (FK_Autista, Codice, Scadenza, Rilascio, Validita)
        VALUES (MatricolaI, CodI, to_date(ScadenzaI, 'yyyy-mm-dd'), to_date(RilascioI, 'yyyy-mm-dd'), ValiditaI);
        gui.REINDIRIZZA(URL||'visualizzazionePatenti?idSessione='||idSessione ||chr(38)||'msg=Inserimento avvenuto con successo'||chr(38)||'err=0' );

    END IF;

    gui.chiudipagina;

    EXCEPTION 
    WHEN OTHERS THEN
        gui.reindirizza(URL||'inserimentoPatente?IDSessione='||IDSessione||chr(38)||'msg='||SQLERRM||chr(38)||'err=1');
        return;
END inserimentoPatente;

procedure invalidaPatente(
    CodI in patenti.Codice%TYPE default null,
    idSessione varchar2 default null
)IS
    ValiditaT number;
BEGIN

    gui.apripagina('Invalida Patente', idSessione);

    IF SessionHandler.getRuolo(idSessione) <> 'Manager'
    THEN
        gui.reindirizza(URL||'visualizzazionePatenti?IDSessione='||IDSessione||chr(38)||'msg=Non hai i permessi necessari'||chr(38)||'err=1');
    ELSE

        SELECT Validita
        INTO ValiditaT
        FROM Patenti
        WHERE Codice =CodI;

        IF ValiditaT=1 THEN 
            UPDATE Patenti
            SET Validita=0
            WHERE Codice =CodI;

            gui.reindirizza(URL||'visualizzazionePatenti?IDSessione='||IDSessione||chr(38)||'msg=Patente invalidata con successo'||chr(38)||'err=0');
        ELSE
            gui.reindirizza(URL||'visualizzazionePatenti?IDSessione='||IDSessione||chr(38)||'msg=La patente non è valida'||chr(38)||'err=1');
        END IF;

    END IF;

    gui.chiudipagina;

    EXCEPTION 
        WHEN OTHERS THEN
            gui.reindirizza(URL||'visualizzazionePatenti?IDSessione='||IDSessione||chr(38)||'msg='||SQLERRM||chr(38)||'err=1');
            return;

END invalidaPatente;

procedure modificaPatente(
    MatricolaI in Dipendenti.Matricola%TYPE default null,
    CodI in patenti.Codice%TYPE default null,
    CodOld in patenti.Codice%TYPE,
    RilascioI varchar2 default null,
    ScadenzaI varchar2 default null,
    ValiditaI number default null,
    idSessione varchar2 default null,
    msg varchar2 default null,
    err number default null
)IS
    ruolo varchar2(20);
    CodT varchar2(20);
    MatricolaT number(20);
    RilascioT date;
    ScadenzaT date;
    ValiditaT number(20);
    elementi gui.Stringarray:=gui.Stringarray();
    reali gui.Stringarray:=gui.Stringarray();
BEGIN

    gui.apripagina('Modifica patente', idSessione);

    if(msg is not null)then 
        if(err=0)then
            gui.AggiungiPopup(true, msg);
        else
            gui.AggiungiPopup(false, msg);
        end if;
    end if;

    ruolo := SessionHandler.getRuolo(idSessione);

    IF ruolo <> 'Manager'
    THEN
        gui.REINDIRIZZA(URL||'visualizzazionePatenti?idSessione='||idSessione||chr(38)||'msg=Non hai i permessi necessari'||chr(38)||'err=1');
    END IF;

    IF CodI IS NULL OR ScadenzaI IS NULL OR RilascioI IS NULL OR ValiditaI IS NULL
    THEN
        SELECT p.FK_Autista,p.Rilascio,p.Scadenza,p.Validita
        INTO MatricolaT,RilascioT,ScadenzaT,ValiditaT
        FROM PATENTI p
        WHERE p.Codice =CodOld;

        FOR autista in(
            SELECT d.Matricola,d.Nome,d.Cognome
            FROM DIPENDENTI d join AUTISTI a on d.Matricola=a.FK_DIPENDENTE
        )LOOP
            elementi.EXTEND;
            reali.EXTEND;
            elementi(elementi.LAST) := (autista.Matricola||' '||autista.Nome||' '||autista.Cognome);          
            reali(reali.LAST) := (autista.Matricola);
        END LOOP;

        IF CodI is null THEN 
            CodT:=CodOld;
        ELSE
            CodT:=CodI;
        END IF;

        gui.AGGIUNGIFORM(url => URL || 'modificaPatente');
        gui.aggiungiintestazione('Modifica patente');

            gui.aggiungigruppoinput;
                gui.AGGIUNGISELEZIONESINGOLA(elementi => elementi, valoreEffettivo=>reali, titolo => 'Autista', ident => 'MatricolaI',optionSelected=>MatricolaT);
                gui.AGGIUNGILABEL(target =>'CodI', testo =>'Codice patente');
                gui.AGGIUNGICAMPOFORM(nome => 'CodI', value => CodT, classeicona=>'fa fa-id-card');
            gui.chiudigruppoinput;

            gui.aggiungigruppoinput;
                gui.apridiv(classe=>'col-half');
                gui.AGGIUNGILABEL(target =>'RilascioI', testo =>'Data di rilascio');
                gui.AGGIUNGICAMPOFORM(tipo => 'date', nome => 'RilascioI', value => TO_CHAR(RilascioT,'YYYY-MM-DD'), classeicona=>'fa fa-calendar');
                gui.chiudidiv;
                gui.apridiv(classe=>'col-half');
                gui.AGGIUNGILABEL(target =>'ScadenzaI', testo =>'Data di scadenza');
                gui.AGGIUNGICAMPOFORM(tipo => 'date', nome => 'ScadenzaI', value => TO_CHAR(ScadenzaT,'YYYY-MM-DD'), classeicona=>'fa fa-calendar');
                gui.chiudidiv;

                
            gui.chiudigruppoinput;

            gui.aggiungigruppoinput;
                gui.AGGIUNGISELEZIONESINGOLA(elementi => gui.Stringarray('Valida', 'Non Valida'), valoreEffettivo=>gui.Stringarray('1', '0'),optionSelected=>ValiditaT, titolo => 'Validità', ident => 'ValiditaI');
            gui.chiudigruppoinput;

            gui.AggiungiCampoFormHidden(nome => 'CodOld', value => CodOld);

            gui.AggiungiCampoFormHidden(nome => 'idSessione', value => idSessione);

            gui.AGGIUNGIBOTTONESUBMIT(value=>'Modifica');
        gui.chiudiform;
 
    ELSIF to_date(ScadenzaI, 'yyyy-mm-dd') > to_date(RilascioI, 'yyyy-mm-dd')
    THEN
        UPDATE Patenti
        SET 
            FK_Autista=MatricolaI,
            Codice=CodI,
            Scadenza=to_date(ScadenzaI, 'yyyy-mm-dd'), 
            Rilascio=to_date(RilascioI, 'yyyy-mm-dd'), 
            Validita=ValiditaI
        WHERE Codice =CodOld;
        gui.REINDIRIZZA(URL||'visualizzazionePatenti?idSessione='||idSessione ||chr(38)||'msg=Modifica avvenuta con successo'||chr(38)||'err=0' );
    ELSE
        gui.REINDIRIZZA(URL||'modificaPatente?IDSessione='||IDSessione||chr(38)||
                            'msg=Errore:La data di scadenza precede quella di rilascio'||chr(38)||
                            'err=1'||chr(38)||
                            'CodOld='||CodOld
                            );
    END IF;

    gui.chiudipagina;

    EXCEPTION 
    WHEN OTHERS THEN
        gui.reindirizza(URL||'visualizzazionePatenti?IDSessione='||IDSessione||chr(38)||'msg='||SQLERRM||chr(38)||'err=1');
        return;
END modificaPatente;

--Domenico
    procedure visualizzaAzioniCorr(
        successo varchar2 default null,
        errore varchar2 default null,
        idSessione varchar2 default null
    )IS
        idRole varchar2(20);
        idUser varchar2(15);
        numeroTaxi int;
    BEGIN
        gui.apriPagina('Visualizza Azioni Correttive', idSessione);
            idRole := SessionHandler.getRuolo(idSessione);
            idUser := SessionHandler.getIDuser(idSessione);
            
            --Un autista non referente non può visualizzare Azioni correttive
            SELECT count(*) INTO numeroTaxi FROM Taxi WHERE FK_Referente = idUser;

            if idRole <> 'Autista' AND idRole <> 'Manager' OR (idRole = 'Autista' AND numeroTaxi = 0) THEN
                gui.AggiungiPopup(false, 'Non hai il permesso per visualizzare questa pagina!', costanti.URL||'gui.homepage?idSessione='||idSessione||chr(38)||'p_success=S');
                gui.chiudipagina;
                return;
            end if;

            gui.aggiungiIntestazione('Azioni correttive disponibili');
            gui.acapo(2);
            if successo is not null then
                gui.aggiungiPopup(true, successo);
                gui.acapo(3);
            elsif errore is not null then
                gui.aggiungipopup(false, errore);
                gui.acapo(3);
            end if;
            gui.BottoneAggiungi(testo => 'Inserisci nuova azione correttiva', url => ''||URL||'inserimentoAzioniCorr?idSessione='||idSessione||'');
            gui.acapo;

            gui.apriTabella(gui.StringArray('Id Azione', 'Azione correttiva', ' '));

                FOR azCorr IN (
                    SELECT * FROM AzioniCorrettive
                )LOOP
                    gui.aggiungiRigaTabella;

                    gui.aggiungiElementoTabella(azCorr.IdAzione);
                    gui.aggiungiElementoTabella(azCorr.Azione);
                    
                    gui.apriElementoPulsanti;
                        gui.aggiungiPulsanteModifica(URL||'modificaAzioneCorr?idSessione='||idSessione||chr(38)||'idAzioneOld='||azCorr.IdAzione);
                    gui.chiudiElementoPulsanti;
                END LOOP;
            gui.chiudiTabella;
        gui.chiudiPagina;
    END visualizzaAzioniCorr;

    procedure inserimentoAzioniCorr(
        idSessione varchar2 default null,
        AzioneCorr varchar2 default null
    )IS
        idRole varchar2(20);
        idUser varchar2(10);
        numeroTaxi int;
        azPresente integer := 0;
        azionePresente exception;
    BEGIN
        gui.apriPagina('Nuova azione correttiva', idSessione);

            idRole := SessionHandler.getRuolo(idSessione);
            idUser := SessionHandler.getIDuser(idSessione);
            
            --Un autista non referente non può inserire Azioni correttive
            SELECT count(*) INTO numeroTaxi FROM Taxi WHERE FK_Referente = idUser;

            if idRole <> 'Autista' AND idRole <> 'Manager' OR (idRole = 'Autista' AND numeroTaxi = 0) THEN
                gui.AggiungiPopup(false, 'Non hai il permesso per visualizzare questa pagina!', costanti.URL||'gui.homepage?idSessione='||idSessione||chr(38)||'p_success=S');
                gui.chiudipagina;
                return;
            end if;
            if AzioneCorr is null then   
                gui.aggiungiIntestazione('Inserisci una nuova azione correttiva');
                gui.acapo(2);

                gui.aggiungiform(url => URL||'inserimentoAzioniCorr');
                    gui.aggiungiGruppoInput;
                        gui.aggiungiCampoForm(nome => 'AzioneCorr', classeIcona => 'fa fa-wrench');
                        gui.aggiungicampoformHidden(nome => 'idSessione', value => idSessione);
                    gui.chiudiGruppoInput;
                    gui.aggiungibottoneSubmit('Inserisci');
                gui.chiudiForm;
            else
                savepoint a1;
                BEGIN
                    SELECT count(*) INTO azPresente FROM azioniCorrettive ac WHERE LOWER(replace(ac.Azione, ' ', '')) = LOWER(replace(AzioneCorr, ' ', ''));

                    if azPresente > 0 then
                        raise azionePresente;
                    end if;

                    INSERT INTO AzioniCorrettive (Azione)
                    VALUES (AzioneCorr);
                    
                    commit;
                END;
                gui.reindirizza(URL||'visualizzaAzioniCorr?idSessione='||idSessione||chr(38)||'successo=Azione inserita con successo');
            end if;
        gui.chiudiPagina;
        EXCEPTION
            WHEN azionePresente THEN
                gui.reindirizza(URL||'visualizzaAzioniCorr?idSessione='||idSessione||chr(38)||'errore=azione correttiva già presente');

            WHEN others THEN
                rollback TO a1;
                gui.reindirizza(URL||'visualizzaAzioniCorr?idSessione='||idSessione||chr(38)||'errore=Errore durante l%27inserimento di una nuova azione correttiva');
                
    END inserimentoAzioniCorr;

    procedure modificaAzioneCorr( 
        idSessione varchar2 default null,
        idAzioneOld varchar2 default null,
        AzioneNew varchar2 default null,
        successo varchar2 default null,
        errore varchar2 default null
    )IS
        idRole varchar2(20);
        idUser int;
        numeroTaxi int;
        nomeAzioneOld varchar2(200);
        azPresente exception;
        azionePresente int := 0;
    BEGIN

        gui.apriPagina('Modifica Azione Correttiva', idSessione);
            idRole := SessionHandler.getRuolo(idSessione);
            idUser := SessionHandler.getIDuser(idSessione);
            
            --Un autista non referente non può modificare azioni correttive
            SELECT count(*) INTO numeroTaxi FROM Taxi WHERE FK_Referente = idUser;

            if idRole <> 'Autista' AND idRole <> 'Manager' OR (idRole = 'Autista' AND numeroTaxi = 0) THEN
                gui.AggiungiPopup(false, 'Non hai il permesso per visualizzare questa pagina!', costanti.URL||'gui.homepage?idSessione='||idSessione||chr(38)||'p_success=S');
                gui.chiudipagina;
                return;
            end if;

            if successo is not null then
                gui.aggiungipopup(true, successo);
            elsif errore is not null then
                gui.aggiungipopup(false, errore);
            end if;
        
            if idAzioneOld is null then 
                gui.aggiungiPopup(false, 'Azione correttiva non trovata', URL||'visualizzaAzioniCorr?idSessione='||idSessione);
                return;
            end if;
            --Prendo l'azione correttiva dall'id
            SELECT Azione INTO nomeAzioneOld FROM AzioniCorrettive WHERE IDAzione = idAzioneOld;

            gui.aggiungiIntestazione('Modifica azione correttiva');
            gui.acapo(2);
            if azioneNew is null then

                gui.aggiungiForm(URL||'modificaAzioneCorr');
                    gui.aggiungiGruppoInput;
                        gui.aggiungiLabel('AzioneNew', 'Azione Correttiva');
                        gui.aggiungicampoForm(nome => 'AzioneNew', value => nomeAzioneOld, classeIcona => 'fa fa-wrench');
                        gui.aggiungicampoFormHidden(nome => 'idSessione', value => idSessione);
                        gui.aggiungicampoFormHidden(nome => 'idAzioneOld', value => idAzioneOld);
                    gui.chiudiGruppoInput;
                    gui.aggiungibottonesubmit('Modifica');
                gui.chiudiForm;
            else
                savepoint modAz;
                BEGIN
                    --Controllo se l'azione correttiva è già presente
                    SELECT count(*) INTO azionePresente FROM AzioniCorrettive ac WHERE lower(REPLACE(azioneNew, ' ', '')) = lower(REPLACE(ac.Azione, ' ', ''));
                    if azionePresente > 0 then
                        raise azPresente;
                    end if;
                    --Modifico l'azione correttiva
                    update AzioniCorrettive set Azione = azioneNew where IDAzione = idAzioneOld;
                    commit;
                END;
                gui.reindirizza(URL||'modificaAzioneCorr?idSessione='||idSessione||chr(38)||'successo=Azione correttiva modificata correttamente'||chr(38)||'idAzioneOld='||idAzioneOld);
            end if;
        gui.chiudiPagina;
        EXCEPTION
            WHEN azPresente THEN
                gui.reindirizza(URL||'modificaAzioneCorr?idSessione='||idSessione||chr(38)||'errore=Azione correttiva già presente'||chr(38)||'idAzioneOld='||idAzioneOld);
            WHEN others THEN
                rollback to modAz;
                gui.reindirizza(URL||'modificaAzioneCorr?idSessione='||idSessione||chr(38)||'errore=Impossibile aggiornare azione correttiva'||chr(38)||'idAzioneOld='||idAzioneOld);
    END modificaAzioneCorr;

    procedure visualizzazioneRevisione(
        Id_Taxi VARCHAR2 default null,
        RisultatoRev in Revisioni.Risultato%TYPE default null,
        InizioScadenzaRev in VARCHAR2 default null,
        ScadenzaRev in VARCHAR2 default null,
        idSessione varchar2 default null,
        popup varchar2 default null,
        idUserFiltro varchar2 default null,
        InizioDataRev varchar2 default null,
        FineDataRev varchar2 default null
    ) IS
        elementi gui.StringArray;
        idUser int;
        idRole varchar2(20);
        numeroTaxi int;

        BEGIN
            gui.APRIPAGINA('Visualizza Revisioni', idSessione);
            idRole := SessionHandler.getRuolo(idSessione);
            idUser := SessionHandler.getIDuser(idSessione);
            
            --Un autista non referente non può visualizzare le revisioni
            SELECT count(*) INTO numeroTaxi FROM Taxi WHERE FK_Referente = idUser; 

            if idRole <> 'Autista' AND idRole <> 'Manager' OR (idRole = 'Autista' AND numeroTaxi = 0) THEN
                gui.AggiungiPopup(false, 'Non hai il permesso per visualizzare questa pagina!', costanti.URL||'gui.homepage?idSessione='||idSessione||chr(38)||'p_success=S');
                gui.chiudipagina;
                return;
            elsif idRole = 'Manager' THEN
                idUser := idUserFiltro;
                elementi := gui.StringArray('Id revisione', 'Targa', 'Risultato', 'Azioni Correttive', 'Effettuata il', 'Scadenza', 'Referente');
            end if;


            gui.AGGIUNGIINTESTAZIONE('Revisioni presenti');
            gui.acapo(2);

            if idRole = 'Autista' then
                
                elementi := gui.StringArray('Id revisione', 'Targa', 'Risultato', 'Azioni Correttive', 'Effettuata il', 'Scadenza', ' ');
                gui.BottoneAggiungi(testo => 'Inserisci nuova revisione', url => ''||URL||'inserimentoRevisione?idSessione='||idSessione||'');
                gui.acapo;
            end if;

            if popup is not null then
                gui.aggiungipopup(false, popup);
                gui.chiudipagina;
                return;
            end if;

            gui.ApriFormFiltro(URL||'visualizzazioneRevisione');
            
                gui.AggiungiCampoFormFiltro(tipo => 'datetime-local', nome => 'InizioDataRev', placeholder => 'Inizio data revisione');
                gui.AggiungiCampoFormFiltro(tipo => 'datetime-local', nome => 'FineDataRev', placeholder => 'Fine data revisione');
                gui.AggiungiCampoFormFiltro(tipo => 'datetime-local', nome => 'InizioScadenzaRev', placeholder => 'Inizio scadenza');
                gui.AggiungiCampoFormFiltro(tipo => 'datetime-local', nome => 'ScadenzaRev', placeholder => 'Fine scadenza');

                gui.AggiungiRigaTabella;
                    if idRole = 'Manager' then
                        gui.AggiungiCampoFormFiltro(tipo => 'text', nome => 'idUserFiltro', value => '', placeholder => 'Id Referente');
                    end if;
                    gui.AggiungiCampoFormFiltro(tipo => 'text', nome => 'Id_Taxi', value => '', placeholder => 'Targa');

                    gui.ApriSelectFormFiltro(nome => 'RisultatoRev', placeholder => 'Risultato revisione');
                        gui.aggiungiOpzioneselect(value => '1', selected => FALSE, testo => 'Passata');
                        gui.aggiungiOpzioneselect(value => '0', selected => FALSE, testo => 'Non passata');
                    gui.chiudiSelectFormFiltro;
                    gui.aggiungicampoFormHidden('text', 'idSessione', idSessione);
                    gui.AggiungiCampoFormFiltro(tipo => 'submit', nome => '', value => 'Filtra', placeholder => 'Filtra');
                gui.chiudiRigaTabella;
            gui.chiudiFormFiltro;

            htp.prn('<br>');

            gui.APRITABELLA(elementi => elementi);
            
            --Query per prendere gli elementi che mi servono nella visualizzazione, controlla se sono stati passati parametri di filtro oppure prende tutti i valori
            for Revisione IN(
            SELECT targa, ris, azione, scadenza, dataOra, Refer, idRevis
            FROM (
                SELECT DISTINCT t.targa as targa, rv.risultato as ris, ac.azione as azione, rv.scadenza as scadenza, rv.dataora, t.fk_referente as Refer, rv.IdRevisione as idRevis,
                            ROW_NUMBER() OVER (PARTITION BY rv.IdRevisione ORDER BY rv.risultato DESC) AS rn
                FROM
                    Taxi t
                JOIN
                    Revisioni rv ON t.IDtaxi = rv.FK_Taxi
                LEFT JOIN
                    AzioniRevisione ar ON rv.IDrevisione = ar.FK_Revisione
                LEFT JOIN
                    AzioniCorrettive ac ON ar.FK_Azione = ac.IDazione
                WHERE
                    (LOWER(REPLACE(t.targa, ' ', '')) = LOWER(REPLACE(Id_Taxi, ' ', '')) OR Id_Taxi IS NULL)
                    AND (rv.risultato = RisultatoRev OR RisultatoRev IS NULL)
                    AND (rv.dataOra >= TO_DATE(REPLACE(InizioDataRev, 'T', ' '), 'yyyy-mm-dd hh24:mi') OR InizioDataRev IS NULL)
                    AND (rv.dataOra <= TO_DATE(REPLACE(FineDataRev, 'T', ' '), 'yyyy-mm-dd hh24:mi') OR FineDataRev IS NULL)
                    AND (rv.scadenza >= TO_DATE(REPLACE(InizioScadenzaRev, 'T', ' '), 'yyyy-mm-dd hh24:mi') OR InizioScadenzaRev IS NULL)
                    AND (rv.scadenza <= TO_DATE(REPLACE(ScadenzaRev, 'T', ' '), 'yyyy-mm-dd hh24:mi') OR ScadenzaRev IS NULL)
                    AND (LOWER(t.FK_Referente) = LOWER(idUser) OR idUser IS NULL)
            ) tmp
            WHERE rn = 1
            order by idRevis
            )
            LOOP
                gui.AGGIUNGIRIGATABELLA;

                gui.AggiungiElementoTabella(Revisione.idRevis);
                gui.AggiungiElementoTabella(Revisione.Targa);

                --Non visualizzo 1/0 ma Successo/Insuccesso
                if Revisione.ris = 1 then
                    gui.AggiungiElementoTabella('Successo');
                else
                    gui.AggiungiElementoTabella('Insuccesso');
                end if;

                gui.AggiungiElementoTabella(Revisione.azione);

                gui.AggiungiElementoTabella(TO_CHAR(Revisione.dataora, 'yyyy-mm-dd hh24:mi'));--Converto le date in char per visualizzarle bene con l'orario

                gui.AggiungiElementoTabella(TO_CHAR(Revisione.scadenza, 'yyyy-mm-dd hh24:mi'));
                
                --Se un autista sta visualizzando le revisioni, allora può anche modificarle
                if idRole = 'Autista' THEN
                    gui.apriElementoPulsanti;
                    gui.aggiungipulsanteModifica(''||URL||'modificaRevisione?'||
                                                't_targa='||Revisione.targa||chr(38)||
                                                'RisultatoRev='||Revisione.ris||chr(38)||
                                                'DataRev='||replace(TO_CHAR(Revisione.dataOra, 'yyyy-mm-dd hh24:mi'), ' ','T')||chr(38)||
                                                'ScadenzaRev='||replace(TO_CHAR(Revisione.scadenza, 'yyyy-mm-dd hh24:mi'), ' ','T')||chr(38)||
                                                'AzioneRev='||Revisione.azione||chr(38)||
                                                'idRev='||Revisione.idRevis||chr(38)||
                                                'idSessione='||idSessione||'');
                    gui.chiudiElementoPulsanti;
                end if;

                if idRole = 'Manager' THEN
                    gui.AggiungiElementoTabella(Revisione.Refer);
                end if;

                gui.ChiudiRigaTabella;
            end LOOP;

            gui.chiudiTabella;
            gui.acapo;

            --gestione eccezioni
            EXCEPTION
                WHEN OTHERS THEN
                    gui.reindirizza(URL||'visualizzazioneRevisione?popup='||SQLERRM||chr(38)||'idSessione='||idSessione);
            gui.chiudiPagina;

        END visualizzazioneRevisione;

    /*---INSERIMENTO REVISIONE---*/

    PROCEDURE inserimentoRevisione(
        RisultatoRev IN revisioni.risultato%TYPE DEFAULT NULL, 
        DataRev varchar2 DEFAULT NULL,
        ScadenzaRev varchar2 DEFAULT NULL,
        AzioneRev IN AzioniCorrettive.Azione%TYPE DEFAULT NULL,
        TaxiRevisionato IN taxi.targa%TYPE DEFAULT NULL,
        successo varchar2 default null,
        errore varchar2 default null,
        azioneCheck varchar2 default null,
        idSessione varchar2 default null
    ) IS
        azioniCorr gui.StringArray := gui.StringArray();
        taxiRev gui.StringArray := gui.StringArray();
        RisRev gui.StringArray := gui.StringArray('1', '0');
        IdAz varchar2(7);
        dataRevConv date;
        dataScadConv date;
        IdUltimaRev varchar2(7);
        TaxiID varchar2(7);
        numeroTaxi int;
        idUser int;
        LastRisRev number;
        LastIdRev number;
        LastDataRev date;
    BEGIN
        --Inserito script javascript per controllare che la data della revisione sia antecedente a quella attuale.  
        gui.APRIPAGINA('Inserisci Revisione', idSessione, '
            function controllaDate() {
                var dataInizio = new Date(document.getElementById("Data_Rev").value);
                var oggi = new Date();

                if(dataInizio.getTime() >= oggi.getTime()){
                    document.getElementById("errore_data_rev").innerHTML = "Data e orario della revisione devono essere antecedenti a data e orario attuali";
                    document.getElementById(''SubmitCheck'').style.visibility = "hidden";
                } else{
                    document.getElementById("errore_data_rev").innerHTML = "";
                    document.getElementById(''SubmitCheck'').style.visibility = "visible";
                }
            }

            window.onload = function() {
                // Aggiungi gli event listener agli input delle date e al select
                document.getElementById("Data_Rev").addEventListener("input", controllaDate);
            };
        ');

        --Inizio controllo sessione, solo gli autisti referenti possono inserire una revisione
        idUser := SessionHandler.getIDuser(idSessione);
        SELECT count(*) INTO numeroTaxi FROM Taxi WHERE FK_Referente = idUser;

        if SessionHandler.getRuolo(idSessione) <> 'Autista' AND numeroTaxi = 0 THEN
            gui.AggiungiPopup(false, 'Non hai il permesso per visualizzare questa pagina!', costanti.URL||'gui.homepage?idSessione='||idSessione||chr(38)||'p_success=S');
            gui.chiudipagina;
            return;
        end if;
        --Fine controllo sessione

        gui.aggiungiIntestazione('Inserisci una nuova revisione');
        gui.acapo;
        --Se la revisione ha avuto successo inserisco un popup con messaggio di successo, altrimenti uno con messaggio di errore
        if successo is not null then
            gui.aggiungiPopup(true, 'Revisione sul taxi '||successo||' aggiunta con successo!');
            gui.acapo(2);
        elsif errore is not null then
            gui.aggiungiPopup(false, 'Errore: '||errore||'');
            gui.acapo(2);
        end if;

        --Primo passo: selezione successo o insuccesso della revisione
        if DataRev is null AND RisultatoRev is null AND ScadenzaRev is NULL AND AzioneRev is null AND TaxiRevisionato is null then

            gui.aggiungiForm(url => ''||URL||'inserimentoRevisione');
            gui.aggiungiSelezioneSingola(elementi => gui.StringArray('Successo', 'Insuccesso'), valoreEffettivo => RisRev, titolo => 'La revisione ha avuto successo?', ident => 'RisultatoRev', firstNull => false);
            gui.aggiungicampoformhidden(nome => 'idSessione', value => idSessione);
            gui.aggiungiBottoneSubmit('Continua');
            gui.chiudiform;

        --Preso il risultato della revisione, passo alla selezione del taxi da revisionare
        elsif DataRev is null AND RisultatoRev is not null AND ScadenzaRev is NULL AND AzioneRev is null AND TaxiRevisionato is null then
            FOR tax IN (
                SELECT targa
                FROM taxi
                WHERE FK_REFERENTE = idUser
            ) LOOP
                taxiRev.EXTEND;
                taxiRev(taxiRev.LAST) := tax.targa;
            END LOOP;

            gui.aggiungiForm(url => ''||URL||'inserimentoRevisione');
            --Stampo un messaggio di successo o errore della revisione e poi invio il vero valore tramite campo hidden
            gui.aggiungiLabel('RisultatoRev', 'Risultato Revisione:');
            if RisultatoRev = 1 then
                gui.aggiungiIntestazione('La revisione ha avuto successo', 'h3');
            else
                gui.aggiungiIntestazione('La revisione non ha avuto successo', 'h3');
            end if;
            gui.aggiungicampoformHidden(nome => 'RisultatoRev', value => RisultatoRev);
            gui.AGGIUNGISELEZIONESINGOLA(elementi => taxiRev, titolo => 'Seleziona il taxi', ident => 'TaxiRevisionato', firstNull => false);
            gui.aggiungicampoformhidden(nome => 'idSessione', value => idSessione);
            gui.aggiungiBottoneSubmit('Continua');

            gui.chiudiForm;
            
            
        --Una volta selezionato il taxi da revisionare passo alla selezione dell'azione correttiva
        elsif DataRev is null AND RisultatoRev is not null AND ScadenzaRev is NULL AND AzioneRev is null AND azioneCheck is null AND TaxiRevisionato is not null then
            
            Select IdTaxi into TaxiID
            FROM Taxi
            WHERE targa = TaxiRevisionato;
            
            SELECT MAX(DataOra)
            INTO LastDataRev
            FROM REVISIONI
            WHERE FK_TAXI = TaxiID;

            SELECT Risultato
            INTO LastRisRev
            FROM REVISIONI
            WHERE FK_TAXI = TaxiID AND DataOra = LastDataRev;

            SELECT idRevisione
            INTO LastIdRev
            FROM REVISIONI
            WHERE FK_TAXI = TaxiID AND DataOra = LastDataRev;
            
            if RisultatoRev=0 then
                gui.reindirizza(URL||'inserimentoRevisione?idSessione='||idSessione||chr(38)||'RisultatoRev=0'||chr(38)||'TaxiRevisionato='||TaxiRevisionato||chr(38)||'AzioneRev='||chr(38)||'azioneCheck=1');
            elsif LastRisRev = 1 then
                gui.reindirizza(URL||'inserimentoRevisione?idSessione='||idSessione||chr(38)||'RisultatoRev=1'||chr(38)||'TaxiRevisionato='||TaxiRevisionato||chr(38)||'AzioneRev='||chr(38)||'azioneCheck=1');
            else
                    
                --Seleziona tutte le azioni correttive
                FOR azioni IN (
                    SELECT Azione
                    FROM AzioniCorrettive
                ) LOOP
                    azioniCorr.EXTEND;
                    azioniCorr(azioniCorr.LAST) := azioni.Azione;
                END LOOP;
                
                gui.aggiungiForm(url => ''||URL||'inserimentoRevisione');

                    gui.AGGIUNGIGRUPPOINPUT;
                    --Stampo un messaggio di errore della revisione e poi invio il vero valore tramite campo hidden
                    gui.aggiungiLabel('RisultatoRev', 'Risultato Revisione:');
                    gui.aggiungiIntestazione('La revisione ha avuto successo', 'h3');
                    gui.aggiungicampoformHidden(nome => 'RisultatoRev', value => RisultatoRev);

                    gui.aggiungiLabel('TaxiRevisionato', 'Taxi revisionato');
                    gui.aggiungiInput(nome => 'TaxiRevisionato', value => TaxiRevisionato, readonly => True);
                    gui.CHIUDIGRUPPOINPUT;
                    gui.AGGIUNGISELEZIONESINGOLA(elementi => azioniCorr, titolo => 'Seleziona azione correttiva', ident => 'AzioneRev', firstNull => false);
                    gui.aggiungicampoformhidden(nome => 'idSessione', value => idSessione);
                    gui.aggiungicampoformhidden(nome => 'azioneCheck', value => '1');
                    gui.aggiungiBottoneSubmit('Continua');

                gui.chiudiForm;
            end if;
            
        --Se ho preso con successo l'azione correttiva, allora l'ultimo step è inserire le date di revisione e di scadenza revisione
        elsif DataRev is null AND RisultatoRev is not null AND ScadenzaRev is NULL AND azioneCheck is not null and TaxiRevisionato is not null then

            
            gui.aggiungiForm(url => ''||URL||'inserimentoRevisione');
            
                --Stampo un messaggio di successo o errore della revisione e poi invio il vero valore tramite campo hidden
                gui.aggiungiLabel('RisultatoRev', 'Risultato Revisione:');
                if RisultatoRev = 1 then
                    gui.aggiungiIntestazione('La revisione ha avuto successo', 'h3');
                else
                    gui.aggiungiIntestazione('La revisione non ha avuto successo', 'h3');
                end if;
                gui.aggiungicampoformHidden(nome => 'RisultatoRev', value => RisultatoRev);

                gui.aggiungiLabel('TaxiRevisionato', 'Taxi revisionato');
                gui.aggiungiInput(nome => 'TaxiRevisionato', value => TaxiRevisionato, readonly => True);
                
                if AzioneRev is not null then
                    gui.aggiungiLabel('AzioneRev', 'Azione revisione');
                    gui.aggiungiInput(nome => 'AzioneRev', value => AzioneRev, readonly => True);
                else
                    gui.aggiungiIntestazione('Azione revisione:', 'h3');
                    gui.aggiungiintestazione('Nessuna azione correttiva selezionata', 'h3');
                end if;
                gui.aggiungicampoformhidden(nome => 'azioneCheck', value => '1');
                gui.aggiungiLabel('DataRev', 'Data revisione');
                gui.aggiungiInput(tipo => 'datetime-local', nome => 'DataRev', required => True, ident => 'Data_Rev');
                htp.prn('<span id="errore_data_rev" style="color: red;"></span>');--Controllo che la data sia > della data attuale, altrimenti lo script mi aggiunge qui un messaggio di errore
                --Scadenza visibile solo se la revisione ha avuto successo
                if RisultatoRev = 1 then
                    gui.AGGIUNGISELEZIONESINGOLA(elementi => gui.StringArray('2 anni','4 anni'), valoreEffettivo => gui.stringArray('2', '4'), titolo => 'Scadenza revisione', ident => 'ScadenzaRev', firstNull => false);
                end if;
                gui.aggiungicampoformhidden(nome => 'idSessione', value => idSessione);

                gui.apriDiv('SubmitCheck');
                    gui.aggiungiBottoneSubmit('Invia');
                gui.chiudiDiv;

            gui.chiudiForm;
        

        elsif DataRev is not null AND RisultatoRev is not null AND azioneCheck is not null and TaxiRevisionato is not null then
            
            dataRevConv:= to_date(replace(DataRev,'T',' ' ),'yyyy-mm-dd hh24:mi');
            dataScadConv := dataRevConv+(365*ScadenzaRev);
            --Inizio sequenza di inserimento della revisione, ho bisogno dell'id del taxi e dell'id dell'azione correttiva
            SAVEPOINT avvioInserimento;

                Select IdTaxi into TaxiID
                FROM Taxi
                WHERE targa = TaxiRevisionato;


                insert into revisioni (FK_taxi, DataOra, Risultato, Scadenza)
                values (TaxiID, DataRevConv, RisultatoRev, dataScadConv)
                RETURNING IdRevisione INTO IdUltimaRev;

                if AzioneRev is not null then

                    Select IDAzione INTO IdAz
                    FROM AzioniCorrettive
                    WHERE Azione = AzioneRev;

                    insert into AzioniRevisione (FK_Azione, FK_Revisione)
                    values (IdAz, IdUltimaRev);
                end if;
            Commit;
                --Fine inserimento revisione
                gui.reindirizza(URL||'inserimentoRevisione?Successo='||TaxiRevisionato||chr(38)||'idSessione='||idSessione);

        end if;

        --Gestione delle eccezioni
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                ROLLBACK TO avvioInserimento;
                gui.reindirizza(URL||'inserimentoRevisione?errore=Taxi o azione correttiva non trovati '||TaxiRevisionato||''||chr(38)||'idSessione='||idSessione);

            WHEN OTHERS THEN
                ROLLBACK TO avvioInserimento;
                gui.reindirizza(URL||'inserimentoRevisione?errore='||SQLERRM||chr(38)||'idSessione='||idSessione);
        
        gui.chiudiPagina();
    END inserimentoRevisione;

    --Procedura accessibile solo ai manager per inserire i dettagli inerenti alla prima revisione di un taxi
PROCEDURE PrimaRevisione(
        t_referente_matr IN taxi.FK_Referente%TYPE,
        t_targa IN taxi.targa%TYPE,
        t_cilindrata in taxi.cilindrata%TYPE,
        t_nposti in taxi.nposti%TYPE,
        t_km in taxi.km%TYPE,
        t_tariffa in taxi.tariffa%TYPE,
        t_tipologia varchar2,
        t_NpersoneDisabili in taxiaccessibile.npersonedisabili%TYPE DEFAULT NULL,
        t_IDoptionals in varchar2 default null,
        idSessione varchar2
    ) IS
    begin
        gui.APRIPAGINA('Inserisci Revisione', idSessione);

        if SessionHandler.getRuolo(idSessione) <> 'Manager' THEN
            gui.AggiungiPopup(false, 'Non hai il permesso per visualizzare questa pagina!', costanti.URL||'gui.homepage?idSessione='||idSessione||chr(38)||'p_success=S');
            gui.chiudipagina;
            return;
        end if;

        CASE t_tipologia
            WHEN 'STANDARD' THEN
                gui.aggiungiIntestazione('Inserisci la prima revisione per un taxi standard');
            WHEN 'ACCESSIBILE' THEN
                gui.aggiungiIntestazione('Inserisci la prima revisione per un taxi accessibile');
            WHEN 'LUSSO' THEN
                gui.aggiungiIntestazione('Inserisci la prima revisione per un taxi di lusso');
        END CASE;

        gui.aggiungiForm(url => u_root||'.gruppo2.insertTaxiRevisione');

        gui.aggiungiGruppoInput;

            gui.aggiungiLabel('DataRev', 'Data revisione');
            gui.aggiungiInput(tipo => 'datetime-local', nome => 'DataRev', required => True, ident => 'Data_Rev');
            --Controllo che la data sia > della data attuale, altrimenti lo script mi aggiunge qui un messaggio di errore
            htp.prn('<span id="errore_data_rev" style="color: red;"></span>');

            gui.aggiungiLabel('ScadRev', 'Data scadenza');
            gui.aggiungiInput(tipo => 'datetime-local', nome => 'ScadRev', required => True, ident => 'Scad_Rev');
            --Controllo che la data di scadenza sia > della data di revisione, altrimenti lo script mi aggiunge qui un messaggio di errore
            htp.prn('<span id="errore_data" style="color: red;"></span>');

        gui.chiudigruppoinput;

        gui.AggiungiCampoFormHidden(nome => 'AzioneRev', value => '');

        gui.AggiungiCampoFormHidden(nome => 't_referente_matr', value => t_referente_matr);
        gui.AggiungiCampoFormHidden(nome => 't_targa', value => t_targa);
        gui.AggiungiCampoFormHidden(nome => 't_cilindrata', value => t_cilindrata);
        gui.AggiungiCampoFormHidden(nome => 't_nposti', value => t_nposti);
        gui.AggiungiCampoFormHidden(nome => 't_km', value => t_km);
        gui.AggiungiCampoFormHidden(nome => 't_tariffa', value => t_tariffa);
        gui.AggiungiCampoFormHidden(nome => 't_tipologia', value => t_tipologia);
        gui.AggiungiCampoFormHidden(nome => 't_NpersoneDisabili', value => t_NpersoneDisabili);
        gui.AggiungiCampoFormHidden(nome => 't_IDoptionals', value => t_IDoptionals);  
        gui.AggiungiCampoFormHidden(nome => 'id_ses', value => idSessione);

        gui.apridiv('SubmitCheck');
            gui.aggiungiBottoneSubmit('Invia');
        gui.chiudiDiv;

        gui.chiudiform;

        --Funzione javascript per controllo date
        gui.chiudipagina('
        function controllaDate() {
            var dataInizio = new Date(document.getElementById("Data_Rev").value);
            var dataFine = new Date(document.getElementById("Scad_Rev").value);
            var oggi = new Date();

            if(dataInizio.getTime() >= oggi.getTime()){
                document.getElementById("errore_data_rev").innerHTML = "Data e orario della revisione devono essere precedenti a data e orario odierni";
                document.getElementById(''SubmitCheck'').style.visibility = "hidden";
            } else{
                document.getElementById("errore_data_rev").innerHTML = "";
                document.getElementById(''SubmitCheck'').style.visibility = "visible";
            }
            if (dataFine <= dataInizio) {
                document.getElementById("errore_data").innerHTML = "La data di scadenza deve essere successiva alla data della revisione";
                document.getElementById(''SubmitCheck'').style.visibility = "hidden";
            } else {
                document.getElementById("errore_data").innerHTML = ""; // Cancella eventuali messaggi di errore precedenti
                document.getElementById(''SubmitCheck'').style.visibility = "visible";
            }
        }

        window.onload = function() {
            // Aggiungi gli event listener agli input delle date
            document.getElementById("Data_Rev").addEventListener("input", controllaDate);
            document.getElementById("Scad_Rev").addEventListener("input", controllaDate);
        };');

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            gui.reindirizza(URL||'inserimentoRevisione?errore=Nessuna azione correttiva disponibile'||chr(38)||'idSessione='||idSessione);
        WHEN others THEN
            gui.reindirizza(URL||'inserimentoRevisione?errore=Si sono verificati dei problemi'||chr(38)||'idSessione='||idSessione);

    end PrimaRevisione;

    --Funzione per inserire la prima revisione, utilizzabile dai manager quando inseriscono un taxi
    --Return boolean che specifica se è stata inserita con successo la revisione o meno
    function inserisciPrimaRev(
        DataRev varchar2,
        ScadenzaRev varchar2,
        AzioneRev in AzioniCorrettive.Azione%TYPE default null,
        TaxiRevisionato in taxi.idtaxi%TYPE
    )
        return boolean
    IS
        IDUltimaRev varchar2(7);
        dataRevConv date;
        dataScadConv date;
        IdAz varchar(7);
        dataErrata exception;
    BEGIN
        dataRevConv:= to_date(replace(DataRev,'T',' ' ),'yyyy-mm-dd hh24:mi');
        dataScadConv:=to_date(replace(ScadenzaRev,'T',' '),'yyyy-mm-dd hh24:mi');

        if dataScadConv<=dataRevConv then
            raise dataErrata;
        end if;

        SAVEPOINT avvioInserimento;

            insert into revisioni (FK_taxi, DataOra, Risultato, Scadenza)
            values (TaxiRevisionato, DataRevConv, '1', dataScadConv)
            RETURNING IdRevisione INTO IdUltimaRev;
            
            IF AzioneRev IS NOT NULL THEN
                Select IDAzione INTO IdAz
                FROM AzioniCorrettive
                WHERE Azione = AzioneRev;

                insert into AzioniRevisione (FK_Azione, FK_Revisione)
                values (IdAz, IdUltimaRev);
            END IF;

        Commit;
        return true;
        
        EXCEPTION
            WHEN dataErrata THEN
                return false;
            WHEN OTHERS THEN
                ROLLBACK TO start_transaction;
                return false;

    END inserisciPrimaRev;

    procedure modificaRevisione(
        t_targa varchar2 default null,
        RisultatoRev IN revisioni.risultato%TYPE default null,
        DataRev varchar2 default null,
        ScadenzaRev varchar2 default null,
        AzioneRev IN AzioniCorrettive.Azione%TYPE default null,
        idSessione varchar2 default null,
        modificato int default 0,
        successo varchar2 default null,
        errore varchar2 default null,
        idRev varchar2 default null
    ) IS
        Id_Taxi varchar2(7);
        azioniCorr gui.StringArray := gui.StringArray();
        taxiRev gui.StringArray := gui.StringArray();
        idUser varchar2(7);
        IdAz varchar(7);
        IdAzRev integer;
        dataErrata exception;
        numeroTaxi int;
        dataRevConv date;
        dataScadConv date;
    BEGIN
        gui.apripagina('Modifica revisione', idSessione);
        --Inizio controlli sessione, solo gli autisti referenti possono modificare la revisione
        idUser := SessionHandler.getIdUser(idSessione);
        if t_targa is null OR RisultatoRev is null OR DataRev is null OR idRev is null then
            gui.aggiungiPopup(false, 'Revisione non trovata', URL||'visualizzazioneRevisione?idSessione='||idSessione);
            return;
        end if;
        --Un autista non referente non può modificare le revisioni
        SELECT count(*) INTO numeroTaxi FROM Taxi WHERE FK_Referente = idUser AND t_targa = Taxi.targa;

        if SessionHandler.getRuolo(idSessione) <> 'Autista' AND numeroTaxi > 0 THEN
            gui.AggiungiPopup(false, 'Non hai il permesso per visualizzare questa pagina!', costanti.URL||'gui.homepage?idSessione='||idSessione||chr(38)||'p_success=S');
            gui.chiudipagina;
            return;
        end if;
        --Fine controlli sessione

        gui.aggiungiIntestazione('Modifica revisione');

        --Se ho effettuato la modifica con successo stampo un popup di successo, altrimenti un errore. 
        if successo is not null then
            gui.aggiungiPopup(true, 'La revisione del taxi '||successo||' è stata aggiornata con successo!');
            gui.acapo;
        elsif errore is not null then
            gui.aggiungiPopup(false, errore);
            gui.acapo;
        end if;

        --modificato = 0 mi indica che l'autista non ha ancora effettuato modifiche
        IF modificato = 0 then
            --Mi servono tutte le azioniCorrettive per poter fare scegliere quella da modificare all'autista
            FOR azioni IN (
                SELECT Azione
                FROM AzioniCorrettive
            ) LOOP
                azioniCorr.EXTEND;
                azioniCorr(azioniCorr.LAST) := azioni.Azione;
            END LOOP;

            --Mi servono tutte le targhe dei taxi referenziati dall'autista per poter fare scegliere quella da modificare
            FOR tax IN (
                SELECT targa
                FROM taxi
                WHERE FK_REFERENTE = idUser
            ) LOOP
                taxiRev.EXTEND;
                taxiRev(taxiRev.LAST) := tax.targa;
            END LOOP;

            --Form per la modifica dei dati che però lascia i dati attuali della revisione di default
            gui.aggiungiform(url => URL||'modificaRevisione');

                gui.aggiungiGruppoInput;
                    gui.aggiungicampoformhidden(nome => 'idRev', value => idRev);

                    gui.aggiungiLabel('DataRev', 'Data revisione');
                    gui.aggiungiCampoForm('datetime-local', 'fa fa-calendar', 'DataRev', value => DataRev, ident => 'Data_Rev');
                    htp.prn('<span id="errore_data_rev" style="color: red;"></span>');

                    if RisultatoRev = 1 then
                        gui.apriDiv('ScadenzaCheck');
                            gui.aggiungiLabel('ScadenzaRev', 'Data scadenza revisione');
                            gui.aggiungiCampoForm('datetime-local', 'fa fa-calendar', 'ScadenzaRev', value => ScadenzaRev, ident => 'Scad_Rev', required => false);
                            htp.prn('<span id="errore_data" style="color: red;"></span>');
                        gui.chiudiDiv;
                        if AzioneRev is not null then
                            htp.prn('<div id="AzioneCheck">');
                                gui.aggiungiSelezioneSingola(elementi => azioniCorr, titolo => 'Azione correttiva', ident => 'AzioneRev', firstNull => True, optionSelected => AzioneRev);
                            gui.chiudiDiv;
                        end if;
                    else
                        htp.prn('<div id="ScadenzaCheck" style="visibility: hidden;">');
                            gui.aggiungiLabel('ScadenzaRev', 'Data scadenza revisione');
                            gui.aggiungiCampoForm('datetime-local', 'fa fa-calendar', 'ScadenzaRev', value => ScadenzaRev, ident => 'Scad_Rev', required => false);
                            htp.prn('<span id="errore_data" style="color: red;"></span>');
                        gui.chiudiDiv;
                        /*if AzioneRev is not null then
                            gui.apriDiv('AzioneCheck');
                                gui.aggiungiSelezioneSingola(elementi => azioniCorr, titolo => 'Azione correttiva', ident => 'AzioneRev', firstNull => True, optionSelected => AzioneRev);
                            gui.chiudiDiv;
                        end if;*/
                    end if;

                    gui.aggiungiSelezioneSingola(elementi => taxiRev, titolo => 'Taxi revisionato', ident => 't_targa', firstNull => False, optionSelected => t_targa);
                    gui.aggiungicampoformhidden(nome => 'idSessione', value => idSessione);

                gui.chiudiGruppoInput;

                gui.apriDiv(classe => 'row');
                gui.AGGIUNGIGRUPPOINPUT;
                    if RisultatoRev = 1 then
                        gui.AGGIUNGIINPUT (nome => 'RisultatoRev', ident => 'successo', tipo => 'radio', value => '1', selected => true);
                        gui.AGGIUNGILABEL (target => 'successo', testo => 'Successo');
                        gui.AGGIUNGIINPUT (nome => 'RisultatoRev', ident => 'insuccesso', tipo => 'radio', value => '0');
                        gui.AGGIUNGILABEL (target => 'insuccesso', testo => 'Insuccesso');
                    else
                        gui.AGGIUNGIINPUT (nome => 'RisultatoRev', ident => 'successo', tipo => 'radio', value => '1');
                        gui.AGGIUNGILABEL (target => 'successo', testo => 'Successo');
                        gui.AGGIUNGIINPUT (nome => 'RisultatoRev', ident => 'insuccesso', tipo => 'radio', value => '0', selected => true);
                        gui.AGGIUNGILABEL (target => 'insuccesso', testo => 'Insuccesso');
                    end if;
                gui.CHIUDIGRUPPOINPUT;
                gui.chiudidiv;
                
                gui.aggiungicampoformhidden(nome => 'modificato', value => '1');
                gui.apriDiv('SubmitCheck');
                    gui.aggiungibottoneSubmit('Modifica');
                gui.chiudiDiv;
            gui.chiudiform;
            gui.acapo(2);
        --Ramo else, ovvero quando l'autista invia delle modifiche da applicare 
        else
            --Converto nel formato corretto le date
            dataRevConv:= to_date(replace(DataRev,'T',' ' ),'yyyy-mm-dd hh24:mi');

            if RisultatoRev = 1 then
                dataScadConv:= to_date(replace(ScadenzaRev,'T',' '),'yyyy-mm-dd hh24:mi');
            else
                dataScadConv:= NULL;
            end if;

            if dataScadConv is not NULL and dataScadConv<=dataRevConv then
                raise dataErrata;
            end if;

            SAVEPOINT update1;
                --Prendo l'Id del taxi 
                select idtaxi into Id_Taxi FROM taxi WHERE LOWER(taxi.targa) = LOWER(t_targa);

                --Aggiorno la revisione con eventuali modifiche applicate
                UPDATE revisioni
                SET FK_taxi = Id_Taxi,
                    DataOra = DataRevConv,
                    Risultato = RisultatoRev,
                    Scadenza = dataScadConv
                WHERE IdRevisione = idRev;
                --Prendo l'id dell'azione correttiva e aggiorno l'azione correttiva effettuata
                IF AzioneRev IS NOT NULL AND RisultatoRev = 1 THEN
                    SELECT IDAzione INTO IdAz
                    FROM AzioniCorrettive
                    WHERE Azione = AzioneRev;
                    
                    UPDATE AzioniRevisione
                    SET FK_Azione = IdAz
                    WHERE FK_Revisione = idRev;

                ELSIF RisultatoRev = 0 THEN
                    DELETE FROM AzioniRevisione WHERE FK_Revisione = idRev;
                END IF;

            Commit;
            gui.reindirizza(URL||'modificaRevisione?t_targa='||t_targa||chr(38)||
                                                'RisultatoRev='||RisultatoRev||chr(38)||
                                                'DataRev='||replace(TO_CHAR(DataRevConv, 'yyyy-mm-dd hh24:mi'), ' ','T')||chr(38)||
                                                'ScadenzaRev='||replace(TO_CHAR(dataScadConv, 'yyyy-mm-dd hh24:mi'), ' ','T')||chr(38)||
                                                'AzioneRev='||AzioneRev||chr(38)||
                                                'idRev='||idRev||chr(38)||
                                                'idSessione='||idSessione||chr(38)||'successo='||t_targa);
        end if;
        --Aggiungo codice javascript per fare il controllo sulle date delle revisioni
        gui.chiudipagina('
            function controllaDate() {
                var dataInizio = new Date(document.getElementById("Data_Rev").value);
                var dataFine = new Date(document.getElementById("Scad_Rev").value);
                var selectValue = getSelectedRadioButtonValue("RisultatoRev");
                var oggi = new Date();

                if(dataInizio.getTime() >= oggi.getTime()){
                    document.getElementById("errore_data_rev").innerHTML = "Data e orario della revisione devono essere precedenti a data e orario odierni";
                    document.getElementById(''SubmitCheck'').style.visibility = "hidden";
                } else{
                    document.getElementById("errore_data_rev").innerHTML = "";
                    document.getElementById(''SubmitCheck'').style.visibility = "visible";
                }
                if (selectValue === "0") {
                    document.getElementById(''ScadenzaCheck'').style.visibility = "hidden";
                    document.getElementById(''AzioneCheck'').style.visibility = "hidden";
                } else {
                    document.getElementById(''ScadenzaCheck'').style.visibility = "visible";
                    document.getElementById(''AzioneCheck'').style.visibility = "visible";
                    if (dataFine <= dataInizio) {
                        document.getElementById("errore_data").innerHTML = "La data di scadenza deve essere successiva alla data della revisione";
                        document.getElementById(''SubmitCheck'').style.visibility = "hidden";
                    } else {
                        document.getElementById("errore_data").innerHTML = ""; // Cancella eventuali messaggi di errore precedenti
                        document.getElementById(''SubmitCheck'').style.visibility = "visible";
                    }
                }
            }

            function getSelectedRadioButtonValue(name) {
                var radioButtons = document.getElementsByName(name);
                for (var i = 0; i < radioButtons.length; i++) {
                    if (radioButtons[i].checked) {
                        return radioButtons[i].value;
                    }
                }
                return null; // Nessun radio button selezionato
            }

            window.onload = function() {
                // Aggiungi gli event listener agli input delle date e al select
                document.getElementById("Data_Rev").addEventListener("input", controllaDate);
                document.getElementById("Scad_Rev").addEventListener("input", controllaDate);
                // Aggiungi event listener per il cambiamento del radio button
                var radioButtons = document.getElementsByName("RisultatoRev");
                radioButtons.forEach(function(radioButton) {
                    radioButton.addEventListener("change", controllaDate);
                });
            };


');

        EXCEPTION 
            WHEN NO_DATA_FOUND THEN
                gui.reindirizza(URL||'modificaRevisione?errore=Nessun taxi presente con quella targa'||chr(38)||'idSessione='||idSessione||chr(38)||'t_targa='||t_targa||chr(38)||'RisultatoRev='||RisultatoRev||chr(38)||'DataRev='||DataRev||chr(38)||'ScadenzaRev='||ScadenzaRev||chr(38)||'AzioneRev='||AzioneRev||chr(38)||'idRev='||idRev);
            WHEN TOO_MANY_ROWS THEN
                Rollback to update1;
                gui.reindirizza(URL||'modificaRevisione?errore=Troppi taxi con questa targa'||chr(38)||'idSessione='||idSessione||chr(38)||'t_targa='||t_targa||chr(38)||'RisultatoRev='||RisultatoRev||chr(38)||'DataRev='||DataRev||chr(38)||'ScadenzaRev='||ScadenzaRev||chr(38)||'AzioneRev='||AzioneRev||chr(38)||'idRev='||idRev);
            WHEN dataErrata THEN
                gui.reindirizza(URL||'modificaRevisione?errore=Data di revisione o di scadenza errata'||chr(38)||'idSessione='||idSessione||chr(38)||'t_targa='||t_targa||chr(38)||'RisultatoRev='||RisultatoRev||chr(38)||'DataRev='||DataRev||chr(38)||'ScadenzaRev='||ScadenzaRev||chr(38)||'AzioneRev='||AzioneRev||chr(38)||'idRev='||idRev);
            WHEN others THEN
                Rollback to update1;
                gui.reindirizza(URL||'modificaRevisione?errore=Si sono verificati dei problemi nella modifica'||chr(38)||'idSessione='||idSessione||chr(38)||'t_targa='||t_targa||chr(38)||'RisultatoRev='||RisultatoRev||chr(38)||'DataRev='||DataRev||chr(38)||'ScadenzaRev='||ScadenzaRev||chr(38)||'AzioneRev='||AzioneRev||chr(38)||'idRev='||idRev);
    END modificaRevisione;

    procedure statisticheRev(
        idSessione varchar2 default null,
        t_targa varchar2 default null,
        nomeRef varchar2 default null,
        cognomeRef varchar2 default null
    )IS
        idRef varchar2(7) := NULL;
        idRole varchar2(15);
        isReferente int;
        elem gui.StringArray;
    BEGIN

        gui.apriPagina('statistiche Revisioni', idSessione);

            idRole := SessionHandler.getRuolo(idSessione);
            idRef := SessionHandler.getIDuser(idSessione);

            SELECT count(*) INTO isReferente FROM Taxi WHERE Fk_Referente = idRef;

            if idRole <> 'Autista' AND idRole <> 'Manager' AND isReferente >= 0 THEN
                gui.AggiungiPopup(false, 'Non hai il permesso per visualizzare questa pagina!', costanti.URL||'gui.homepage?idSessione='||idSessione||chr(38)||'p_success=S');
                gui.chiudipagina;
                return;
            elsif idRole = 'Manager' THEN
                idRef := NULL;
                elem := gui.StringArray('Targa', 'Revisioni passate', 'Revisioni fallite', 'Nome referente');
            elsif idRole = 'Autista' THEN
                elem := gui.StringArray('Targa', 'Revisioni passate', 'Revisioni fallite');
            end if;

            gui.aggiungiIntestazione('Statistiche sulle revisioni');
            gui.acapo;

            gui.ApriFormFiltro(URL||'statisticheRev');

                gui.AggiungiCampoFormFiltro(tipo => 'text', nome => 't_targa', placeholder => 'Targa');

                if idRole = 'Manager' then
                    gui.AggiungiCampoFormFiltro(tipo => 'text', nome => 'NomeRef', placeholder => 'Nome referente');
                    gui.AggiungiCampoFormFiltro(tipo => 'text', nome => 'cognomeRef', placeholder => 'Cognome referente');
                end if;
                gui.aggiungicampoFormHidden('text', 'idSessione', idSessione);
                gui.AggiungiCampoFormFiltro(tipo => 'submit', nome => '', value => 'Filtra', placeholder => 'Filtra');
            
            gui.chiudiFormFiltro;
            
            gui.apriTabella(elementi => elem);

                for stats in(
                    SELECT *
                    FROM VistaRevisioniTaxiRef v 
                    WHERE 
                        (idRef is null or v.Referente = idRef) AND
                        (t_targa IS NULL OR LOWER(REPLACE(v.Targa, ' ', '')) = LOWER(REPLACE(t_targa, ' ', ''))) AND
                        (nomeRef IS NULL OR LOWER(REPLACE(v.Nome, ' ', '')) = LOWER(REPLACE(nomeRef, ' ', ''))) AND
                        (cognomeRef IS NULL OR LOWER(REPLACE(v.Cognome, ' ', '')) = LOWER(REPLACE(cognomeRef, ' ', '')))
                )
                LOOP
                    gui.AGGIUNGIRIGATABELLA;

                        gui.AggiungiElementoTabella(stats.Targa);
                        gui.AggiungiElementoTabella(stats.Revisioni_Passate);
                        gui.AggiungiElementoTabella(stats.Revisioni_Fallite);
                        if idRole = 'Manager' then
                            gui.AggiungiElementoTabella(stats.Nome||' '||stats.Cognome);
                        end if;
                    gui.ChiudiRigaTabella;
                END LOOP;

            gui.chiudiTabella;
        gui.chiudipagina;
        EXCEPTION
            WHEN others THEN
                gui.aggiungiIntestazione(SQLERRM);
                return;
    END statisticheRev;

    --Statistica sul numero di applicazioni di ogni azione correttiva
    procedure statisticheAzCorr(
        idSessione varchar2 default null
    )IS
        idRole varchar2(15);
        idRef varchar2(10);
        isReferente int;
        RevSenzaAzione int;
        numTot int;
    BEGIN
        gui.apriPagina('Statistiche Azioni Correttive', idSessione);
            
            idRole := SessionHandler.getRuolo(idSessione);
            
            --Controllo se l'utente ha il permesso di visualizzare questa pagina
            if idRole <> 'Manager' THEN
                gui.AggiungiPopup(false, 'Non hai il permesso per visualizzare questa pagina!', costanti.URL||'gui.homepage?idSessione='||idSessione||chr(38)||'p_success=S');
                gui.chiudipagina;
                return;
            end if;

            SELECT Numero INTO RevSenzaAzione FROM NumRevSenzaAzioniView;
            SELECT count(*) INTO numTot FROM azioniCorrettive;
            
            gui.aggiungiIntestazione('Numero di applicazioni di ogni azione correttiva');

            gui.aggiungiIntestazione('Le revisioni senza azioni correttive collegate sono '||RevSenzaAzione, 'h3');

            gui.apriTabella(elementi=> gui.StringArray('Azione', 'Numero di applicazioni', 'Percentuale'));
                for azStat in (
                    SELECT * FROM AzioniCorrView
                )
                LOOP
                    gui.aggiungirigaTabella;
                        gui.aggiungiElementoTabella(azStat.Azione);
                        gui.aggiungiElementoTabella(azStat.NumRevisioni);
                        gui.aggiungiElementoTabella(TRUNC((azStat.NumRevisioni/numTot)*100, 2)||'%');
                    gui.chiudiRigaTabella;
                END LOOP;

            gui.chiudiTabella();

        gui.chiudiPagina;
    END statisticheAzCorr;

--Danilo
    procedure visualizzazioneDipendenti(
        VMatricola in Dipendenti.Matricola%TYPE default null,
        VNome in Dipendenti.Nome%TYPE default null,
        VCognome in Dipendenti.Cognome%TYPE default null,
        VDataNascita VARCHAR2 default null,
        VNtelefono VARCHAR2 default null,
        VSesso varchar default '',
        VStato VARCHAR default '1',
        VCF VARCHAR2 default '',
        VBonus VARCHAR2 default '',
        VIndirizzo Dipendenti.Indirizzo%TYPE default null,
        Ruolo VARCHAR2 default null,
        Neopatentato VARCHAR default null,
        StatoPatente NUMBER default 0,
        error NUMBER default 0,
        Submit VARCHAR2 default '',
        idSessione varchar2 default null
    ) IS

        elementi gui.StringArray;
        ides gui.StringArray;
        els gui.StringArray;
        valide NUMBER(3) default 0;
        dp DATE;
        b BOOLEAN;
        notResponsabile exception;
        idUser int;
        idRole varchar2(20);
        r VARCHAR2(200);
        pippo gui.stringarray;

    BEGIN

        gui.APRIPAGINA('Visualizza Dipendenti', idSessione);

        idUser := SessionHandler.getIDuser(idSessione);
        idRole := SessionHandler.getRuolo(idSessione);

        elementi := gui.StringArray('Matricola', 'Nome', 'Cognome', 'Bonus', 'Qualifica', 'Stato Patente', 'Stato', 'Opzioni');

        IF error=-1
        THEN
            gui.AGGIUNGIPOPUP(successo=>false);
        ELSIF error = 1
        THEN
            gui.AGGIUNGIPOPUP(successo=>true, testo=>'Cancellazione Riuscita');
        ELSIF error = 2
        THEN
            gui.AGGIUNGIPOPUP(successo=>true, testo=>'Modifica Riuscita');
        ELSIF error = 20
        THEN
            gui.AGGIUNGIPOPUP(successo=>true, testo=>'Modifica Fallita');
        ELSIF error = 21
        THEN
            gui.AGGIUNGIPOPUP(successo=>true, testo=>'Modifica Fallita, Parametri Errati');  
        ELSIF error = 22
        THEN
            gui.AGGIUNGIPOPUP(successo=>true, testo=>'Modifica Fallita, Permessi Insufficienti');    
        ELSIF error = 10
        THEN
            gui.AGGIUNGIPOPUP(successo=>false, testo=>'Cancellazione Fallita');
        ELSIF error = 11
        THEN
            gui.AGGIUNGIPOPUP(successo=>false, testo=>'Cancellazione Fallita, Dipendente Essenziale Per Lo Storico');
        ELSIF error = 12
        THEN
            gui.AGGIUNGIPOPUP(successo=>false, testo=>'Cancellazione Fallita, Permessi Insufficienti');
        ELSIF error = 30
        THEN
            gui.AGGIUNGIPOPUP(successo=>false, testo=>'Visualizzazione Fallita, Dipendente Non Esiste');
        ELSIF error = 31
        THEN
            gui.AGGIUNGIPOPUP(successo=>false, testo=>'Visualizzazione Fallita, ID Dipendente Assente');
        END IF;


        IF idRole='Manager' OR idRole='Contabile'
        THEN

            gui.aggiungiintestazione('LISTA DIPENDENTI');
            gui.ApriFormFiltro(URL||'visualizzazioneDipendenti');

            gui.AGGIUNGICAMPOFORMFILTRO(nome => 'VMatricola', placeholder => 'Matricola', value => VMatricola);
            gui.AGGIUNGICAMPOFORMFILTRO(nome => 'VNome', placeholder => 'Nome', value=>VNome);
            gui.AGGIUNGICAMPOFORMFILTRO(nome => 'VCognome', placeholder => 'Cognome', value=>VCognome);

            gui.ApriSelectFormFiltro(nome=>'VSesso', placeholder=>'Sesso');
            gui.aggiungiOpzioneselect('', VSesso<>'M' AND VSesso<>'F' AND VSesso<>'N', 'Tutti');
            gui.aggiungiOpzioneselect('N', VSesso='N', 'Non Specificato');
            gui.aggiungiOpzioneselect('M', VSesso='M', 'Maschio');
            gui.aggiungiOpzioneselect('F', VSesso='F', 'Femmina');
            gui.chiudiSelectFormFiltro;

            gui.ApriSelectFormFiltro(nome => 'Neopatentato', placeholder => 'Neopatentato');
            gui.aggiungiOpzioneselect('', Neopatentato<>'1' AND Neopatentato<>'0', 'Entrambi');
            gui.aggiungiOpzioneselect('1', Neopatentato='1', 'Neopatentato');
            gui.aggiungiOpzioneselect('0', Neopatentato='0', 'Patente Standard');
            gui.chiudiSelectFormFiltro;

            gui.ApriSelectFormFiltro(nome => 'StatoPatente', placeholder => 'Stato Patente');
            gui.aggiungiOpzioneselect(0, StatoPatente<>1 AND StatoPatente<>2, 'Entrambi');
            gui.aggiungiOpzioneselect(1, StatoPatente=1, 'Valida');
            gui.aggiungiOpzioneselect(2, StatoPatente=2, 'Non Valida');
            gui.chiudiSelectFormFiltro;

            gui.ApriSelectFormFiltro(nome=>'VStato', placeholder=>'Stato');
            gui.aggiungiOpzioneselect('', VStato<>1 AND VStato<>0, 'Entrambi');
            gui.aggiungiOpzioneselect('1', VStato=1, 'Attivo');
            gui.aggiungiOpzioneselect('0', Vstato=0, 'Disattivo');
            gui.chiudiSelectFormFiltro;

            gui.AggiungiCampoFormHidden(nome=>'Ruolo');
            ides := gui.Stringarray('Autista', 'Operatore', 'Manager', 'Contabile', 'SenzaRuolo');
            els :=  gui.Stringarray('Autisti', 'Operatori', 'Manager', 'Contabili', 'SenzaRuolo');
            gui.aggiungiDropdownFormFiltro(testo=>'Ruoli', ids=>ides, names=>els, hiddenParameter=>'Ruolo', placeholder=>'');
            gui.aggiungicampoformhidden(nome => 'idSessione', value => idSessione);

            gui.AGGIUNGICAMPOFORMFILTRO(tipo=>'submit', nome=>'Submit', placeholder=>'Filtra');
            
            
            gui.CHIUDIFORMFILTRO;    
        END IF;


        gui.acapo();

        IF Ruolo IS NOT NULL
        THEN
            pippo := stringtoarray(Ruolo);
        END IF;
    --AUTISTI
        if 'Autista' member OF pippo OR Ruolo is null OR idRole='Autista' 
        then
            b:=true;

            for Dipendente IN (
                SELECT d.Matricola, d.CF, d.Nome, d.Cognome, d.DataNascita, d.Sesso, d.Ntelefono, d.Indirizzo, d.Email, d.EmailAziendale, d.Bonus, d.Stato, d.password, a.DataPatente
                FROM Dipendenti d 
                    JOIN Autisti a on d.Matricola = a.FK_Dipendente
                WHERE
                    (
                        (VNome IS NULL OR lower(d.Nome) LIKE ('%' || lower(VNome) || '%')) AND
                        (VCognome IS NULL OR lower(d.Cognome) LIKE ('%' || lower(VCognome) || '%')) AND
                        (VMatricola IS NULL OR d.Matricola = VMatricola) AND
                        (VDataNascita IS NULL OR d.DataNascita = TO_DATE(VDataNascita, 'yyyy/mm/dd')) AND
                        (VNtelefono IS NULL OR d.Ntelefono = VNtelefono) AND
                        (VSesso IS NULL OR d.Sesso = VSesso) AND
                        (VStato IS NULL OR d.Stato = VStato) AND
                        (VCF IS NULL OR d.CF = VCF) AND
                        (VBonus IS NULL OR d.Bonus = VBonus) AND
                        (VIndirizzo IS NULL OR d.Indirizzo = VIndirizzo)AND
                        (
                            (StatoPatente=1 AND 0<(SELECT count(*) FROM Patenti p WHERE d.Matricola = p.FK_Autista AND p.Validita = '1') ) OR
                            (StatoPatente=2 AND 0=(SELECT count(*) FROM Patenti p WHERE d.Matricola = p.FK_Autista AND p.Validita = '1') ) OR
                            (StatoPatente=0)
                        )AND
                        (
                            (Neopatentato='1' AND (sysdate - a.DataPatente)/365 < 1) OR
                            (Neopatentato='0' AND (sysdate - a.DataPatente)/365 > 1) OR
                            (Neopatentato IS NULL)
                        )AND
                        (idRole='Manager' OR idRole='Contabile')
                    )
                    OR
                    (
                        (idRole<>'Cliente') AND
                        (d.Matricola=idUser)
                    )
                ORDER BY d.Matricola)
                LOOP

                    SELECT count(*) into valide FROM Patenti p WHERE Dipendente.Matricola = p.FK_Autista AND p.Validita = 1;
                        
                    if(b)
                    THEN
                        IF idRole='Manager' OR idRole='Contabile'
                        THEN
                            gui.aggiungiintestazione('AUTISTI');
                        ELSE
                            gui.aggiungiintestazione('AUTISTA');
                        END IF;

                        gui.APRITABELLA(elementi);
                        b:= false;
                    end if;

                    gui.AGGIUNGIRIGATABELLA;
                    gui.AGGIUNGIELEMENTOTABELLA(Dipendente.Matricola);
                    gui.AGGIUNGIELEMENTOTABELLA(Dipendente.Nome);
                    gui.AGGIUNGIELEMENTOTABELLA(Dipendente.Cognome);
                    gui.AGGIUNGIELEMENTOTABELLA(Dipendente.Bonus);

                    IF (sysdate - Dipendente.DataPatente)/365 < 1
                    THEN
                        gui.AGGIUNGIELEMENTOTABELLA('Neopatentato');   
                    ELSE
                        gui.AggiungiElementoTabella('Patente regolare');
                    end if;

                    IF valide > 0 
                    THEN
                        gui.AGGIUNGIELEMENTOTABELLA('Valida');
                    ELSE
                        gui.AGGIUNGIELEMENTOTABELLA('Non Valida');
                    END IF;

                    IF Dipendente.Stato = 1
                    THEN
                        gui.AGGIUNGIELEMENTOTABELLA('Attivo');
                    ELSE
                        gui.AGGIUNGIELEMENTOTABELLA('Non Attivo');
                    END IF;


                    gui.aprielementopulsanti;
                        gui.AggiungiPulsanteGenerale(testo=>'Visualizza', collegamento=> ''''|| URL || 'visualizzaDipendente?' 
                                                                                                    || 'IMatricola=' || Dipendente.Matricola || chr(38) 
                                                                                                    ||'idSessione=' || idSessione||'''');
                        gui.AGGIUNGIPULSANTECANCELLAZIONE(''''|| URL|| 'cancellaDipendente?' 
                                                                    || 'VMatricola=' || Dipendente.Matricola || chr(38)
                                                                    ||'idSessione=' || idSessione||'''');
                    gui.chiudielementopulsanti;

                    --gui.AGGIUNGIELEMENTOTABELLA('   ');
                    gui.ChiudiRigaTabella;
            END LOOP;

            if(not b)
            then
                gui.chiudiTabella;
            end if;
        end if;

    --OPERATORI
        elementi := gui.StringArray('Matricola', 'Nome', 'Cognome', 'Bonus','Stato', 'Opzioni');
        if 'Operatore' member OF pippo OR Ruolo is null OR idRole='Operatore'
            then
            b := true;

            for Dipendente IN (
                SELECT d.Matricola, d.CF, d.Nome, d.Cognome, d.DataNascita, d.Sesso, d.Ntelefono, d.Indirizzo, d.Email, d.EmailAziendale, d.Bonus, d.Stato, d.password
                FROM Dipendenti d JOIN Operatori o on d.Matricola = o.FK_Dipendente
                WHERE(
                        (VNome IS NULL OR lower(d.Nome) LIKE ('%' || lower(VNome) || '%')) AND
                        (VCognome IS NULL OR lower(d.Cognome) LIKE ('%' || lower(VCognome) || '%')) AND
                        (VMatricola IS NULL OR d.Matricola = VMatricola) AND
                        (VDataNascita IS NULL OR d.DataNascita = TO_DATE(VDataNascita, 'yyyy/mm/dd')) AND
                        (VNtelefono IS NULL OR d.Ntelefono = VNtelefono) AND
                        (VSesso IS NULL OR d.Sesso = VSesso) AND
                        (VStato IS NULL OR d.Stato = VStato) AND
                        (VCF IS NULL OR d.CF = VCF) AND
                        (VBonus IS NULL OR d.Bonus = VBonus) AND
                        (VIndirizzo IS NULL OR d.Indirizzo = VIndirizzo) AND
                        (idRole='Manager' OR idRole='Contabile')
                    )
                    OR
                    (
                        (idRole<>'Cliente') AND
                        (d.Matricola=idUser)
                    )
                ORDER BY d.Matricola)
                LOOP

                if(b)
                THEN
                    IF idRole='Manager' OR idRole='Contabile'
                    THEN
                        gui.aggiungiintestazione('OPERATORI');
                    ELSE
                        gui.aggiungiintestazione('OPERATORE');
                    END IF;

                    gui.APRITABELLA(elementi);
                    b:= false;
                end if;


                gui.AGGIUNGIRIGATABELLA;
                gui.AGGIUNGIELEMENTOTABELLA(Dipendente.Matricola);
                gui.AGGIUNGIELEMENTOTABELLA(Dipendente.Nome);
                gui.AGGIUNGIELEMENTOTABELLA(Dipendente.Cognome);
                gui.AGGIUNGIELEMENTOTABELLA(Dipendente.Bonus);    

                IF Dipendente.Stato = 1
                THEN
                    gui.AGGIUNGIELEMENTOTABELLA('Attivo');
                ELSE
                    gui.AGGIUNGIELEMENTOTABELLA('Non Attivo');
                END IF;            
                
                gui.aprielementopulsanti;
                    gui.AggiungiPulsanteGenerale(testo=>'Visualizza', collegamento=> ''''|| URL || 'visualizzaDipendente?' 
                                                                                                || 'IMatricola=' || Dipendente.Matricola || chr(38) 
                                                                                                ||'idSessione=' || idSessione||'''');
                    gui.AGGIUNGIPULSANTECANCELLAZIONE(''''|| URL|| 'cancellaDipendente?' 
                                                                || 'VMatricola=' || Dipendente.Matricola || chr(38)
                                                                ||'idSessione=' || idSessione||'''');
                gui.chiudielementopulsanti;

                gui.chiudirigatabella;
            END LOOP;

            if(not b)
            then
                gui.chiudiTabella;
            end if;
        end if;
    --MANAGER
        if 'Manager' member OF pippo OR Ruolo is null
            then
            b:= true;

            for Dipendente IN (
                SELECT d.Matricola, d.CF, d.Nome, d.Cognome, d.DataNascita, d.Sesso, d.Ntelefono, d.Indirizzo, d.Email, d.EmailAziendale, d.Bonus, d.Stato, d.password
                FROM Dipendenti d JOIN RESPONSABILI r on d.Matricola = r.FK_DIPENDENTE
                WHERE(
                        (VNome IS NULL OR lower(d.Nome) LIKE ('%' || lower(VNome) || '%')) AND
                        (VCognome IS NULL OR lower(d.Cognome) LIKE ('%' || lower(VCognome) || '%')) AND
                        (VMatricola IS NULL OR d.Matricola = VMatricola) AND
                        (VDataNascita IS NULL OR d.DataNascita = TO_DATE(VDataNascita, 'yyyy/mm/dd')) AND
                        (VNtelefono IS NULL OR d.Ntelefono = VNtelefono) AND
                        (VSesso IS NULL OR d.Sesso = VSesso) AND
                        (VStato IS NULL OR d.Stato = VStato) AND
                        (VCF IS NULL OR d.CF = VCF) AND
                        (VBonus IS NULL OR d.Bonus = VBonus) AND
                        (VIndirizzo IS NULL OR d.Indirizzo = VIndirizzo) AND
                        (r.Ruolo = 1) AND
                        (idRole='Manager' OR idRole='Contabile')
                    )
                    OR
                    (
                        (idRole<>'Cliente') AND
                        (d.Matricola=idUser)
                    )
                ORDER BY d.Matricola)
                LOOP

                if(b)
                THEN
                    gui.aggiungiintestazione('MANAGER');

                    gui.APRITABELLA(elementi);
                    b:= false;
                end if;

                gui.AGGIUNGIRIGATABELLA;
                gui.AGGIUNGIELEMENTOTABELLA(Dipendente.Matricola);
                gui.AGGIUNGIELEMENTOTABELLA(Dipendente.Nome);
                gui.AGGIUNGIELEMENTOTABELLA(Dipendente.Cognome);
                gui.AGGIUNGIELEMENTOTABELLA(Dipendente.Bonus);    

                IF Dipendente.Stato = 1
                THEN
                    gui.AGGIUNGIELEMENTOTABELLA('Attivo');
                ELSE
                    gui.AGGIUNGIELEMENTOTABELLA('Non Attivo');
                END IF;
                
                gui.aprielementopulsanti;
                    gui.AggiungiPulsanteGenerale(testo=>'Visualizza', collegamento=> ''''|| URL || 'visualizzaDipendente?' 
                                                                                                || 'IMatricola=' || Dipendente.Matricola || chr(38) 
                                                                                                ||'idSessione=' || idSessione||'''');
                    gui.AGGIUNGIPULSANTECANCELLAZIONE(''''|| URL|| 'cancellaDipendente?' 
                                                                || 'VMatricola=' || Dipendente.Matricola || chr(38)
                                                                ||'idSessione=' || idSessione||'''');
                gui.chiudielementopulsanti;
                gui.chiudirigatabella;
            END LOOP;

            if(not b)
            then
                gui.chiudiTabella;
            end if;
        end if;
    --CONTABILI
        if 'Contabile' member OF pippo OR Ruolo is null
            then
            b:= true;

            for Dipendente IN (
                SELECT d.Matricola, d.CF, d.Nome, d.Cognome, d.DataNascita, d.Sesso, d.Ntelefono, d.Indirizzo, d.Email, d.EmailAziendale, d.Bonus, d.Stato, d.password
                FROM Dipendenti d JOIN RESPONSABILI r on d.Matricola = r.FK_DIPENDENTE
                WHERE(
                        (VNome IS NULL OR lower(d.Nome) LIKE ('%' || lower(VNome) || '%')) AND
                        (VCognome IS NULL OR lower(d.Cognome) LIKE ('%' || lower(VCognome) || '%')) AND
                        (VMatricola IS NULL OR d.Matricola = VMatricola) AND
                        (VDataNascita IS NULL OR d.DataNascita = TO_DATE(VDataNascita, 'yyyy/mm/dd')) AND
                        (VNtelefono IS NULL OR d.Ntelefono = VNtelefono) AND
                        (VSesso IS NULL OR d.Sesso = VSesso) AND
                        (VStato IS NULL OR d.Stato = VStato) AND
                        (VCF IS NULL OR d.CF = VCF) AND
                        (VBonus IS NULL OR d.Bonus = VBonus) AND
                        (VIndirizzo IS NULL OR d.Indirizzo = VIndirizzo) AND
                        (r.Ruolo = 0) AND
                        (idRole='Manager' OR idRole='Contabile')
                    )
                    OR
                    (
                        (idRole<>'Cliente') AND
                        (d.Matricola=idUser)
                    )
                ORDER BY d.Matricola)
                LOOP

                if(b)
                THEN
                    IF idRole='Manager' OR idRole='Contabile'
                    THEN
                        gui.aggiungiintestazione('CONTABILI');    
                    ELSE
                        gui.aggiungiintestazione('CONTABILE');
                    END IF;

                    gui.APRITABELLA(elementi);
                    b:= false;
                end if;

                gui.AGGIUNGIRIGATABELLA;
                gui.AGGIUNGIELEMENTOTABELLA(Dipendente.Matricola);
                gui.AGGIUNGIELEMENTOTABELLA(Dipendente.Nome);
                gui.AGGIUNGIELEMENTOTABELLA(Dipendente.Cognome);
                gui.AGGIUNGIELEMENTOTABELLA(Dipendente.Bonus);  

                IF Dipendente.Stato = 1
                THEN
                    gui.AGGIUNGIELEMENTOTABELLA('Attivo');
                ELSE
                    gui.AGGIUNGIELEMENTOTABELLA('Non Attivo');
                END IF;
            
                gui.aprielementopulsanti;
                    gui.AggiungiPulsanteGenerale(testo=>'Visualizza', collegamento=> ''''|| URL || 'visualizzaDipendente?' 
                                                                                                || 'IMatricola=' || Dipendente.Matricola || chr(38) 
                                                                                                ||'idSessione=' || idSessione||'''');
                    gui.AGGIUNGIPULSANTECANCELLAZIONE(''''|| URL|| 'cancellaDipendente?' 
                                                                || 'VMatricola=' || Dipendente.Matricola || chr(38)
                                                                ||'idSessione=' || idSessione||'''');
                gui.chiudielementopulsanti;
                gui.chiudirigatabella;
            END LOOP;

            if(not b)
            then
                gui.chiudiTabella;
            end if; 
        end if;
    --SENZA RUOLO

        if 'SenzaRuolo'member OF pippo OR Ruolo is null 
            then
            b := true;

            for Dipendente IN (
                SELECT d.Matricola, d.CF, d.Nome, d.Cognome, d.DataNascita, d.Sesso, d.Ntelefono, d.Indirizzo, d.Email, d.EmailAziendale, d.Bonus, d.Stato, d.password
                FROM Dipendenti d
                WHERE(
                        (VNome IS NULL OR lower(d.Nome) LIKE ('%' || lower(VNome) || '%')) AND
                        (VCognome IS NULL OR lower(d.Cognome) LIKE ('%' || lower(VCognome) || '%')) AND
                        (VMatricola IS NULL OR d.Matricola = VMatricola) AND
                        (VDataNascita IS NULL OR d.DataNascita = TO_DATE(VDataNascita, 'yyyy/mm/dd')) AND
                        (VNtelefono IS NULL OR d.Ntelefono = VNtelefono) AND
                        (VSesso IS NULL OR d.Sesso = VSesso) AND
                        (VStato IS NULL OR d.Stato = VStato) AND
                        (VCF IS NULL OR d.CF = VCF) AND
                        (VBonus IS NULL OR d.Bonus = VBonus) AND
                        (VIndirizzo IS NULL OR d.Indirizzo = VIndirizzo) AND
                        (d.Matricola not in (SELECT a.FK_Dipendente FROM Autisti a)) AND
                        (d.Matricola not in (SELECT o.FK_Dipendente FROM Operatori o)) AND
                        (d.Matricola not in (SELECT r.FK_Dipendente FROM Responsabili r))AND
                        (idRole='Manager' OR idRole='Contabile')
                    )
                    OR
                    (
                        (idRole<>'Cliente') AND
                        (d.Matricola=idUser) AND
                        (d.Matricola not in (SELECT a.FK_Dipendente FROM Autisti a)) AND
                        (d.Matricola not in (SELECT o.FK_Dipendente FROM Operatori o)) AND
                        (d.Matricola not in (SELECT r.FK_Dipendente FROM Responsabili r))
                    )

                ORDER BY d.Matricola)
                LOOP

                if(b)
                THEN
                    gui.aggiungiintestazione('SENZA RUOLO');

                    gui.APRITABELLA(elementi);
                    b:= false;
                end if;


                gui.AGGIUNGIRIGATABELLA;
                gui.AGGIUNGIELEMENTOTABELLA(Dipendente.Matricola);
                gui.AGGIUNGIELEMENTOTABELLA(Dipendente.Nome);
                gui.AGGIUNGIELEMENTOTABELLA(Dipendente.Cognome);
                gui.AGGIUNGIELEMENTOTABELLA(Dipendente.Bonus);  

                IF Dipendente.Stato = 1
                THEN
                    gui.AGGIUNGIELEMENTOTABELLA('Attivo');
                ELSE
                    gui.AGGIUNGIELEMENTOTABELLA('Non Attivo');
                END IF;
                
                gui.aprielementopulsanti;
                    gui.AggiungiPulsanteGenerale(testo=>'Visualizza', collegamento=> ''''|| URL || 'visualizzaDipendente?' 
                                                                                                || 'IMatricola=' || Dipendente.Matricola || chr(38) 
                                                                                                ||'idSessione=' || idSessione||'''');
                    gui.AGGIUNGIPULSANTECANCELLAZIONE(''''|| URL|| 'cancellaDipendente?' 
                                                                || 'VMatricola=' || Dipendente.Matricola || chr(38)
                                                                ||'idSessione=' || idSessione||'''');
                gui.chiudielementopulsanti;
                gui.chiudirigatabella;
            END LOOP;

            if(not b)
            then
                gui.chiudiTabella;
            end if;
        end if;
        gui.acapo(3);
        gui.CHIUDIPAGINA;
    END visualizzazioneDipendenti;


    procedure visualizzaDipendente(
        IMatricola in Dipendenti.matricola%TYPE default null,
        error NUMBER default 0,
        idSessione VARCHAR2 default null
    )IS
        Dipendente Dipendenti%ROWTYPE;
        sex varchar2(20);
        dp Date;
        elementi gui.StringArray;
        idUser int;
        idRole varchar2(20);
        ruol integer default 0;
    BEGIN

        gui.apripagina('Visualizzazione Dipendente', idSessione);
        idUser := SessionHandler.getIDuser(idSessione);
        idRole := SessionHandler.getRuolo(idSessione);

        IF idRole = 'Cliente'
        THEN
            gui.AGGIUNGIPOPUP(successo=>false, testo=>'Visualizzazione Fallita, Permessi Non Sufficienti');
        ELSE

            SELECT count(*)
            INTO ruol
            FROM Dipendenti d
            WHERE d.Matricola = IMatricola;
            IF ruol=0 AND IMatricola IS NOT NULL
            THEN
                gui.AGGIUNGIPOPUP(successo=>false, testo=>'Visualizzazione Fallita, Dipendente Non Esiste');
            ELSE

                IF IMatricola IS NULL
                THEN
                    SELECT *
                    INTO Dipendente
                    FROM Dipendenti d
                    WHERE d.Matricola = idUser;

                    if idRole = 'Autista'
                    THEN
                        SELECT DataPatente
                        INTO dp
                        FROM Autisti
                        WHERE FK_Dipendente = idUser;
                    END IF;
                ELSE
                    ruol := 0;

                    SELECT *
                    INTO Dipendente
                    FROM Dipendenti d
                    WHERE d.Matricola = IMatricola;

                    SELECT count(*)
                    INTO ruol
                    FROM Autisti a
                    WHERE a.FK_Dipendente = IMatricola;

                    if ruol>0
                    THEN
                        SELECT DataPatente
                        INTO dp
                        FROM Autisti
                        WHERE FK_Dipendente = IMatricola;
                    END IF;

                END IF;

                gui.AGGIUNGIFORM(url =>URL || 'modificaDipendente');
                gui.AGGIUNGIINTESTAZIONE('Dati Dipendente', 'h2');

                gui.acapo(2);

                gui.aggiungigruppoinput;
                gui.AGGIUNGILABEL(target =>'IMatricola', testo =>'Matricola');
                gui.AGGIUNGIINPUT(nome => 'IMatricola', value => Dipendente.Matricola, readonly=>true);

                gui.AGGIUNGILABEL(target =>'VNome', testo =>'Nome');
                gui.AGGIUNGIINPUT(nome => 'VNome', value => Dipendente.Nome, readonly=>true);
                gui.chiudigruppoinput;
                gui.AGGIUNGILABEL(target =>'VCognome', testo =>'Cognome');
                gui.AGGIUNGIINPUT(nome => 'VCognome', value => Dipendente.Cognome, readonly=>true);
                

                IF Dipendente.Sesso = 'M'
                THEN
                    sex := 'Maschio';
                ELSIF Dipendente.Sesso = 'F'
                THEN
                    sex := 'Femmina';
                ELSE
                    sex := 'Non Specificato';
                END IF;

                
                gui.AGGIUNGILABEL(target =>'VSesso', testo =>'Genere');
                gui.AGGIUNGIINPUT(nome => 'VSesso', value=>Dipendente.Sesso, readonly=>true);
                
                gui.AGGIUNGILABEL(target =>'VDataNascita', testo =>'Data di Nascita');
                gui.AGGIUNGIINPUT(tipo => 'date', nome => 'VDataNascita', value =>to_char(Dipendente.DataNascita, 'yyyy-mm-dd'), readonly=>true);

                gui.AGGIUNGILABEL(target =>'VCF', testo =>'Codice Fiscale');
                gui.AGGIUNGIINPUT(nome => 'VCF', value => Dipendente.CF, readonly=>true);

                gui.AGGIUNGILABEL(target =>'VNtelefono', testo =>'Numero di Telefono');
                gui.AGGIUNGIINPUT(nome => 'VNtelefono', value => Dipendente.NTelefono, readonly=>true);

                gui.AGGIUNGILABEL(target =>'VEmail', testo =>'Email');
                gui.AGGIUNGIINPUT(nome => 'VEmail', value => Dipendente.Email, readonly=>true);

                gui.AGGIUNGILABEL(target =>'VEmailAziendale', testo =>'Email Aziendale');
                gui.AGGIUNGIINPUT(nome => 'VEmailAziendale', value => Dipendente.EmailAziendale, readonly=>true);

                gui.AGGIUNGILABEL(target =>'VIndirizzo', testo =>'Indirizzo');
                gui.AGGIUNGIINPUT(nome => 'VIndirizzo', value => Dipendente.Indirizzo, readonly=>true);

                gui.AGGIUNGILABEL(target =>'VBonus', testo =>'Bonus');
                gui.AGGIUNGIINPUT(tipo => 'number', nome => 'VBonus', value => Dipendente.Bonus, readonly=>true);


                IF Dipendente.stato = '1'
                THEN
                    gui.AGGIUNGILABEL(target =>'VStato', testo =>'Stato');
                    gui.AGGIUNGIINPUT(nome => 'VStato', value => 'Attivo', readonly=>true);
                ELSE
                    gui.AGGIUNGILABEL(target =>'VStato', testo =>'Stato');
                    gui.AGGIUNGIINPUT(nome => 'VStato', value => 'Disattivo', readonly=>true);
                END IF;
                
                
                gui.AGGIUNGILABEL(target =>'Ruolo', testo =>'Ruolo');

                IF Dipendente.Matricola IS NULL
                THEN
                    gui.aggiungiinput(nome=>'Ruolo', value=>idRole, readonly=>true);
                ELSIF ruol>0
                THEN
                    gui.aggiungiinput(nome=>'Ruolo', value=>'Autista', readonly=>true);
                    gui.AGGIUNGILABEL(target =>'VDataPatente', testo =>'Data di Prima Patente');
                    gui.AGGIUNGIINPUT(tipo => 'date', nome => 'VDataPatente', value => to_char(dp, 'YYYY-MM-DD'), readonly=>true);
                ELSE
                    SELECT count(*) INTO ruol FROM Responsabili r WHERE r.FK_Dipendente = Dipendente.Matricola AND r.Ruolo = 0;
                    IF ruol>0
                    THEN
                        gui.aggiungiinput(nome=>'Ruolo', value=>'Manager', readonly=>true);
                    ELSE
                        SELECT count(*) INTO ruol FROM Responsabili r WHERE r.FK_Dipendente = Dipendente.Matricola AND r.Ruolo = 1;
                        IF ruol>0
                        THEN
                            gui.aggiungiinput(nome=>'Ruolo', value=>'Contabile', readonly=>true);
                        ELSE
                            SELECT count(*) INTO ruol FROM Operatori o WHERE o.FK_Dipendente = Dipendente.Matricola;
                            IF ruol>0
                            THEN
                                gui.aggiungiinput(nome=>'Ruolo', value=>'Operatore', readonly=>true);
                            ELSE
                                gui.aggiungiinput(nome=>'Ruolo', value=>'Nessuno', readonly=>true);
                            END IF;
                        END IF;
                    END IF;
                END IF;
                gui.AggiungiCampoFormHidden(nome=>'idSessione', value=>idSessione);

                IF (idRole = 'Manager' AND IMatricola IS NOT NULL) OR (IMatricola IS NULL)
                THEN
                    gui.aggiungiBottoneSubmit(value=>'Modifica');
                END IF;

                gui.chiudiform;
            END IF;
        END IF;    
        gui.chiudipagina();
    END visualizzaDipendente;



    procedure modificaDipendente(
        IMatricola in Dipendenti.Matricola%TYPE default null,
        VNome in Dipendenti.Nome%TYPE default null,
        VCognome in Dipendenti.Cognome%TYPE default null,
        VDataNascita VARCHAR2 default null,
        VNtelefono VARCHAR2 default null,
        VSesso varchar default '',
        VStato VARCHAR default '',
        VCF VARCHAR2 default '',
        VBonus VARCHAR2 default '',
        VIndirizzo Dipendenti.Indirizzo%TYPE default null,
        VEmailAziendale Dipendenti.EmailAziendale%TYPE default null,
        VEmail Dipendenti.Email%TYPE default NULL,
        VdataPatente VARCHAR2 default NULL,
        error NUMBER default 0,
        Ruolo VARCHAR2 default '',
        idSessione varchar2 default null
    )IS
        elementi gui.Stringarray;
        reali gui.Stringarray;
        idUser int;
        idRole varchar2(20);
        e exception;
    BEGIN
        
        gui.APRIPAGINA('Visualizzazione Dipendente', idSessione);
        idUser := SessionHandler.getIDuser(idSessione);
        idRole := SessionHandler.getRuolo(idSessione);

        IF (idUser <> IMatricola AND idRole <> 'Manager')
        THEN
            raise e;
        END IF;

        gui.AGGIUNGIFORM(url => URL || 'updateDipendente');
        gui.aggiungiintestazione('MODIFICA DIPENDENTE');

        IF idRole = 'Manager'
        THEN
            
            IF VStato = 'Attivo'
            THEN 
                elementi := gui.Stringarray('Attivo', 'Disattivo');
                reali := gui.Stringarray('1', '0');
            ELSE
                elementi := gui.Stringarray('Disattivo', 'Attivo');
                reali := gui.Stringarray('0', '1');
            END IF;

            gui.aggiungigruppoinput;
                gui.apridiv(classe=>'col-third');
                    gui.AGGIUNGILABEL(target =>'VMatricola', testo =>'Matricola');
                    gui.AGGIUNGIINPUT(nome => 'VMatricola', value => IMatricola, readonly=>true);
                gui.chiudidiv();
                gui.apridiv(classe=>'col-third');
                gui.chiudidiv;
                gui.apridiv(classe=>'col-half');
                    gui.AGGIUNGISELEZIONESINGOLA(elementi => elementi, valoreEffettivo=>reali, titolo => 'Stato', ident => 'VStato');
                gui.chiudidiv;
            gui.chiudigruppoinput;

            gui.aggiungigruppoinput;
                gui.apridiv(classe=>'col-half');
                    gui.AGGIUNGILABEL(target =>'VNome', testo =>'Nome');
                    gui.AGGIUNGIINPUT(nome => 'VNome', value => VNome);
                gui.chiudidiv();

                gui.apridiv(classe=>'col-half');      
                    gui.AGGIUNGILABEL(target =>'VCognome', testo =>'Cognome');
                    gui.AGGIUNGIINPUT(nome => 'VCognome', value => VCognome);
                gui.chiudidiv();
            gui.chiudigruppoinput;

            gui.aggiungigruppoinput;
            
                gui.apridiv(classe=>'col-half');
                    gui.AGGIUNGILABEL(target =>'VDataNascita', testo =>'Data di Nascita');
                    gui.AGGIUNGIINPUT(tipo => 'date', nome => 'VDataNascita', value => VDataNascita);
                gui.chiudidiv;
                
                gui.apridiv(classe=>'col-half');
                    if Ruolo = 'Autista'
                    then
                        gui.AGGIUNGILABEL(target =>'VDataPatente', testo =>'Data di Prima Patente');
                        gui.AGGIUNGIINPUT(tipo => 'date', nome => 'VDataPatente', value => VDataPatente);
                    end if;
                gui.chiudidiv;
            gui.chiudigruppoinput;

            IF VSesso = 'M'
            THEN
                elementi := gui.Stringarray('M', 'F', 'N');
                reali := gui.Stringarray('Maschio', 'Femmina', 'Nessuno');
            ELSIF VSesso = 'F'
            THEN
                elementi := gui.Stringarray('F', 'M', 'N');
                reali := gui.Stringarray('Femmina', 'Maschio', 'Nessuno');
            ELSE
                elementi := gui.Stringarray('N', 'M', 'F');
                reali := gui.Stringarray('Nessuno', 'Maschio', 'Femmina');
            END IF;

            gui.aggiungigruppoinput;
                gui.apridiv(classe=>'col-third');
                    gui.AGGIUNGILABEL(target =>'VCF', testo =>'Codice Fiscale');
                    gui.AGGIUNGIINPUT(nome => 'VCF', value => VCF);
                gui.chiudidiv;
                gui.apridiv(classe=>'col-third');
                gui.chiudidiv;
                gui.apridiv(classe=>'col-half');
                    gui.AGGIUNGISELEZIONESINGOLA(valoreEffettivo => elementi, elementi=> reali, titolo => 'Sesso', ident => 'VSesso');
                gui.chiudidiv;
            gui.chiudigruppoinput;

            gui.aggiungigruppoinput; 
                gui.apridiv(classe=>'col-half');
                    gui.AGGIUNGILABEL(target =>'VIndirizzo', testo =>'Indirizzo');
                    gui.AGGIUNGIINPUT(nome => 'VIndirizzo', value => VIndirizzo);
                gui.chiudidiv; 
                gui.apridiv(classe=>'col-half');
                    gui.AGGIUNGILABEL(target =>'VNtelefono', testo =>'Numero di Telefono');
                    gui.AGGIUNGIINPUT(nome => 'VNtelefono', value => VNtelefono);
                gui.chiudidiv;
            gui.chiudigruppoinput;
        
            gui.aggiungigruppoinput; 
                gui.apridiv(classe=>'col-half');
                    gui.AGGIUNGILABEL(target =>'VEmail', testo =>'Email');
                    gui.AGGIUNGIINPUT(nome => 'VEmail', value => VEmail);
                gui.chiudidiv; 
                gui.apridiv(classe=>'col-half');
                    gui.AGGIUNGILABEL(target =>'VEmailAziendale', testo =>'Email Aziendale');
                    gui.AGGIUNGIINPUT(nome => 'VEmailAziendale', value => VEmailAziendale);
                gui.chiudidiv;
            gui.chiudigruppoinput;


            gui.aggiungigruppoinput;

                gui.apridiv(classe=>'col-half');
                    gui.AGGIUNGILABEL(target =>'VBonus', testo =>'Bonus');
                    gui.AGGIUNGIINPUT(tipo => 'number', nome => 'VBonus', value => VBonus);
                gui.chiudidiv;
            gui.chiudigruppoinput;

            gui.aggiungiinput(tipo=>'hidden', nome=>'Ruolo', value=>Ruolo);
        END IF;

        IF idUser = IMatricola
        THEN
            gui.aggiungigruppoinput;
                gui.apridiv(classe=>'col-full');
                gui.AGGIUNGILABEL(target =>'VPassword', testo =>'Vecchia Password');
                gui.AGGIUNGIINPUT(tipo=>'password', nome => 'VPassword', value => null, placeholder=>'Inserisci vecchia password per cambiarla');
                gui.chiudidiv;
            gui.chiudigruppoinput;
            gui.aggiungigruppoinput;
                gui.apridiv(classe=>'col-full');
                gui.AGGIUNGILABEL(target =>'NPassword', testo =>'Nuova Password');
                gui.AGGIUNGIINPUT(tipo=>'password', nome => 'NPassword', value => null, placeholder=>'Lascia vuota per non modificare');
                gui.chiudidiv;
            gui.chiudigruppoinput;
        END IF;

        gui.AggiungiCampoFormHidden(nome=>'idSessione', value=>idSessione);

        gui.AGGIUNGIBOTTONESUBMIT(value=>'Submit');

        gui.CHIUDIFORM; 
        gui.chiudiPagina;

        EXCEPTION
        WHEN e THEN gui.REINDIRIZZA(URL||'visualizzazioneDipendenti?error=22' || chr(38) || 'idSessione='||idSessione);
        

    END modificaDipendente;

    procedure updateDipendente(
        VMatricola in Dipendenti.Matricola%TYPE default null,
        VNome in Dipendenti.Nome%TYPE default null,
        VCognome in Dipendenti.Cognome%TYPE default null,
        VDataNascita VARCHAR2 default null,
        VNtelefono VARCHAR2 default null,
        VSesso varchar default null,
        VPassword Dipendenti.Password%TYPE default null,
        NPassword Dipendenti.Password%TYPE default null,
        VStato VARCHAR2 default null,
        VCF VARCHAR2 default null,
        VBonus VARCHAR2 default null,
        VIndirizzo Dipendenti.Indirizzo%TYPE default null,
        VEmailAziendale Dipendenti.EmailAziendale%TYPE default null,
        VEmail Dipendenti.Email%TYPE default null,
        Ruolo VARCHAR2 default null,
        VDataPatente VARCHAR2 default null,
        error NUMBER default 0,
        idSessione varchar2 default null
    ) IS
        st Number(1) default 1;
        idUser int;
        idRole varchar2(20);
        vpass Dipendenti.Password%TYPE default null;
        e exception;
    BEGIN

        gui.APRIPAGINA('Update Dipendente', idSessione);
        idUser := SessionHandler.getIDuser(idSessione);
        idRole := SessionHandler.getRuolo(idSessione);

        IF (idUser <> VMatricola AND idRole <> 'Manager')
        THEN
            raise e;
        END IF;

        if (VStato <> '0' AND VStato <> '1') OR (VSesso <> 'M' AND VSesso <> 'N' AND VSesso <> 'F')
        THEN
            gui.REINDIRIZZA(URL||'visualizzazioneDipendenteR?error=21' || chr(38) || 'idSessione=' || idSessione);
        ELSE

            UPDATE Dipendenti
            SET 
                Nome = VNome,
                Cognome = VCognome,
                DataNascita = to_date(VDataNascita, 'YYYY-MM-DD'),
                Ntelefono = VNtelefono,
                Sesso = VSesso,
                Stato = st,
                CF = VCF,
                Bonus = VBonus,
                Indirizzo = VIndirizzo,
                EmailAziendale = VEmailAziendale,
                Email = VEmail
            WHERE Matricola = VMatricola;

            IF VPassword IS NOT NULL AND NPassword IS NOT NULL
            THEN
                SELECT d.password
                INTO vpass
                FROM Dipendenti d
                WHERE d.Matricola = VMatricola;

                IF vpass = VPassword
                THEN
                    UPDATE Dipendenti
                    SET 
                        Password = NPassword
                    WHERE Matricola = VMatricola;
                END IF;
            END IF;

            if VDataPatente is not null 
            then
                UPDATE Autisti a
                SET
                    DataPatente = to_date(VDataPatente, 'YYYY-MM-DD')
                WHERE a.FK_Dipendente = VMatricola;
            end if;


            gui.REINDIRIZZA(URL||'visualizzazioneDipendenti?error=2' || chr(38) || 'idSessione='||idSessione);
        END IF;
        gui.chiudipagina;

        EXCEPTION
        WHEN e THEN gui.REINDIRIZZA(URL||'visualizzazioneDipendenti?error=22' || chr(38) || 'idSessione='||idSessione);
        WHEN OTHERS THEN gui.REINDIRIZZA(URL||'visualizzazioneDipendenti?error=20' || chr(38) || 'idSessione='||idSessione);
    END updateDipendente;

    procedure cancellaDipendente(
        VMatricola in Dipendenti.Matricola%TYPE default null,
        idSessione varchar2 default null
    ) IS

        n1 INTEGER default 0;
        n2 INTEGER default 0;
        n3 INTEGER default 0;
        n4 INTEGER default 0;
        Ruolo VARCHAR2(12) default null;
        e exception;
    BEGIN

        gui.APRIPAGINA('Visualizza Dipendenti', idSessione);

        IF SessionHandler.getRuolo(idSessione) <> 'Manager'
        THEN
            raise e;
        END IF;

        SELECT count(*) INTO n1 FROM Autisti WHERE FK_Dipendente = VMatricola;
        SELECT count(*) INTO n2 FROM Operatori WHERE FK_Dipendente = VMatricola;
        SELECT count(*) INTO n3 FROM Responsabili WHERE FK_Dipendente = VMatricola AND Ruolo = 0; -- Manager
        SELECT count(*) INTO n4 FROM Responsabili WHERE FK_Dipendente = VMatricola AND Ruolo = 1;
        
        IF n1>0
        THEN 
            Ruolo:='Autista';
        ELSIF n2>0
        THEN
            Ruolo:='Operatore';
        ELSIF n3>0
        THEN
            Ruolo:='Manager';
        ELSIF n4>0
        THEN
            Ruolo:='Contabile';
        ELSE
            Ruolo:='Nessuno';
        END IF;
    --Autisti: turni, taxi, patenti
        IF Ruolo = 'Autista'
        THEN
            SELECT count(*) INTO n1 FROM Turni WHERE FK_Autista = VMatricola;
            SELECT count(*) INTO n2 FROM Taxi WHERE FK_Referente = VMatricola;
            SELECT count(*) INTO n3 FROM Patenti WHERE FK_Autista = VMatricola;
    --Contabili: Bustapaga
        ELSIF Ruolo = 'Contabile'
        THEN
            SELECT count(*) INTO n1 FROM Bustepaga WHERE FK_Contabile = VMatricola;
    --Operatori: NonAnonime
        ELSIF Ruolo = 'Operatore'
        THEN
            SELECT count(*) INTO n1 FROM NonAnonime WHERE FK_Operatore = VMatricola;
    --Manager: Turni
        ELSIF Ruolo = 'Manager'
        THEN
            SELECT count(*) INTO n1 FROM Turni WHERE FK_Manager = VMatricola;
        END IF;
    --Tutti: Bustapaga
        IF Ruolo <> 'Nessuno'
        THEN
            SELECT count(*) INTO n4 FROM Bustepaga WHERE FK_Dipendente = VMatricola;
        END IF;
    --DELETE        
        IF (n1=0 AND n2=0 AND n3=0 AND n4=0)
        THEN
            IF Ruolo='Autista'
            THEN
                DELETE 
                FROM Autisti a 
                WHERE 
                a.FK_Dipendente = VMatricola;
            ELSIF Ruolo='Operatore'
            THEN
                DELETE 
                FROM Operatori o 
                WHERE 
                o.FK_Dipendente = VMatricola;
            ELSIF Ruolo='Manager' OR Ruolo='Contabile'
            THEN
                DELETE 
                FROM Responsabili r 
                WHERE 
                r.FK_Dipendente = VMatricola;
            END IF;
            DELETE 
            FROM DIPENDENTI d 
            WHERE 
                d.matricola = VMatricola;
            
            gui.REINDIRIZZA(URL||'visualizzazioneDipendenti?Error=1'|| chr(38) || 'idSessione='||idSessione);
        ELSE
            gui.REINDIRIZZA(URL||'visualizzazioneDipendenti?Error=11'|| chr(38) || 'idSessione='||idSessione);
        END IF;

        EXCEPTION
        WHEN e THEN gui.REINDIRIZZA(URL||'visualizzazioneDipendenti?Error=12'|| chr(38) || 'idSessione='||idSessione);
        WHEN OTHERS THEN gui.REINDIRIZZA(URL||'visualizzazioneDipendenti?Error=10'|| chr(38) || 'idSessione='||idSessione);

    END cancellaDipendente;

    function stringToArray(string in varchar2, delimiter in varchar2 default ';')
            return gui.StringArray
            is outputArray gui.StringArray:=gui.StringArray();
            begin
                for x in (
                    WITH rws AS (
                            SELECT string FROM dual
                        )
                        SELECT regexp_substr(
                    string,
                    '[^'||delimiter||']+',
                    1,
                    LEVEL
                ) value
                        FROM rws
                        CONNECT BY LEVEL <= LENGTH(string) - LENGTH(REPLACE(string, delimiter)) + 1
                    ) loop
                        outputArray.extend;
                        outputArray(outputArray.COUNT):=x.value;
                        end loop;   
                RETURN outputArray;
    end stringToArray;

--Carolina
procedure visualizzazioneTurni(
    IDAutista in Dipendenti.Matricola%TYPE default null,
    NomeAutista in Dipendenti.Nome%TYPE default null,
    CognomeAutista in Dipendenti.Cognome%TYPE default null,
    Taxi in Taxi.IDtaxi%TYPE default null,
    DataInizio  varchar2 default null,
    Datafine  varchar2 default null,
    errore varchar2 default null,
    successo varchar2 default null,
    idSessione varchar2 default null
) AS
    elementi gui.StringArray;
    inizio date;
    ruolo varchar(20);
    temp date;
    fine date;
    BEGIN
        elementi := gui.StringArray('IDAutista','Nome Autista','Cognome Autista', 'Taxi','Data Inizio', 'Data Fine', 'Inizio Effettivo', 'Fine Effettivo',' ');
        gui.APRIPAGINA('Visualizza Turni',idSessione); 
        ruolo :=SessionHandler.getRuolo(idSessione);

        --controllo diritti
        if  ruolo<> 'Manager' AND ruolo<>'Operatore' THEN
            gui.AggiungiPopup(false, 'Non hai il permesso per visualizzare questa pagina!');
            gui.acapo(3);
            gui.bottoneaggiungi(testo => 'Ritorna alla home', url =>costanti.URL ||'gui.homepage?idSessione='||IDSessione||chr(38)||'p_success=S');
            gui.chiudipagina;
            return;
        end if;
        --visualizzo messaggi errore o successo
        if(errore is not null) then
        gui.AggiungiPopup(successo=>false,testo=>errore);
        gui.Acapo(2);
        elsif(successo is not null) then 
        gui.AggiungiPopup(successo=>true,testo=>successo);
        gui.aCapo(2);
        end if;
        gui.aggiungiIntestazione(testo => 'Visualizza Turni');
        gui.aCapo(2);
        --solo il manager può inserire i turni
        if(ruolo='Manager') then
            gui.BottoneAggiungi(testo=>'Inserisci turno', url=>''||URL||'inserimentoTurni'||
                '?idSessione='||idSessione||''); 
            gui.aCapo;
        end if;
        gui.ApriFormFiltro(''||URL||'visualizzazioneTurni');

        gui.AGGIUNGICAMPOFORMFILTRO(nome=>'IDAutista',placeholder=>'Matricola'); 
        gui.AggiungiCampoFormFiltro(nome => 'NomeAutista', placeholder => 'Nome');
        gui.AggiungiCampoFormFiltro(nome => 'CognomeAutista', placeholder => 'Cognome');
        gui.AggiungiCampoFormFiltro(nome => 'Taxi', placeholder => 'Taxi');
        gui.AggiungiCampoFormFiltro(tipo => 'datetime-local', nome => 'DataInizio', placeholder => 'Inizio ');
        gui.AggiungiCampoFormFiltro(tipo => 'datetime-local', nome => 'DataFine', placeholder => 'Fine');
        gui.AggiungiCampoformHidden(nome=>'idSessione',value=>idSessione);
        gui.AggiungiCampoFormFiltro('submit', '', '', 'filtra');
        gui.chiudiFormFiltro;

        gui.aCapo;
        --se non specificata data inizio si visualizza dall'orario e giorno attuale
        if(DataInizio is null) THEN inizio:=sysdate;
        else inizio:= TO_DATE(replace(DataInizio,'T',' '), 'yyyy-mm-dd hh24:mi');
        end if;
        
        fine:=TO_DATE(replace(DataFine,'T',' '), 'yyyy-mm-dd hh24:mi');
        --se fine minore di inizio si invertono
        if(fine<inizio and DataInizio is not null)then
            temp:=inizio;
            inizio:=fine;
            fine:=temp;
        end if;
        

        gui.APRITABELLA(elementi); 
        if(ruolo='Operatore') THEN      
        --non ha la possibilità di modifica e/o eliminazione      
        for turno in
        (SELECT d.matricola,d.nome, d.cognome, t.FK_Taxi, t.DataOraInizio, t.DataOraFine, t.DataOraInizioEff, t.DataOraFineEff 
        FROM Turni t 
        JOIN Autisti a ON a.FK_DIPENDENTE = t.FK_AUTISTA
        JOIN Dipendenti d ON d.Matricola = a.FK_DIPENDENTE
        WHERE 
            (IDAutista is null or d.Matricola = trim(IDAutista)) and
            (NomeAutista IS NULL OR lower(d.nome) like '%'||trim(lower(NomeAutista))||'%') AND
            (CognomeAutista IS NULL OR lower(d.cognome) like '%'||trim(lower(CognomeAutista))||'%') AND
            (Taxi IS NULL OR t.FK_Taxi like '%'||Taxi) AND
            (t.DataOraInizio >inizio) AND
            (DataFine IS NULL OR  t.DataOraInizio < fine) 
        order by t.DataOraInizio)

        LOOP
            gui.AGGIUNGIRIGATABELLA;
            
            gui.AGGIUNGIELEMENTOTABELLA(turno.Matricola);
            gui.AggiungiElementoTabella(turno.Nome);
            gui.AggiungiElementoTabella(turno.Cognome);
            gui.AggiungiElementoTabella(turno.FK_Taxi);
            gui.AggiungiElementoTabella(to_char(turno.DataOraInizio,'yyyy-mm-dd hh24:mi'));
            gui.AggiungiElementoTabella(to_char(turno.DataOraFine,'yyyy-mm-dd hh24:mi'));
            gui.AggiungiElementoTabella(to_char(turno.DataOraInizioEff,'yyyy-mm-dd hh24:mi'));
            gui.AggiungiElementoTabella(to_char(turno.DataOraFineEff,'yyyy-mm-dd hh24:mi'));
        end LOOP;

        else
       for turno IN
        (SELECT d.matricola,d.nome, d.cognome, t.FK_Taxi, t.DataOraInizio, t.DataOraFine, t.DataOraInizioEff, t.DataOraFineEff 
        FROM Turni t 
        JOIN Autisti a ON a.FK_DIPENDENTE = t.FK_AUTISTA
        JOIN Dipendenti d ON d.Matricola = a.FK_DIPENDENTE
        WHERE 
            (IDAutista is null or d.Matricola = trim(IDAutista)) and
            (NomeAutista IS NULL OR lower(d.nome) like '%'||trim(lower(NomeAutista))||'%') AND
            (CognomeAutista IS NULL OR lower(d.cognome) like '%'||trim(lower(CognomeAutista))||'%') AND
            (Taxi IS NULL OR t.FK_Taxi =trim(Taxi)) AND
            (t.DataOraInizio >inizio) AND

            (DataFine IS NULL OR  t.DataOraInizio < fine) 
        order by t.DataOraInizio) 
        
        LOOP
            gui.AGGIUNGIRIGATABELLA;
            
            gui.AGGIUNGIELEMENTOTABELLA(turno.Matricola);
            gui.AggiungiElementoTabella(turno.Nome);
            gui.AggiungiElementoTabella(turno.Cognome);
            gui.AggiungiElementoTabella(turno.FK_Taxi);
            gui.AggiungiElementoTabella(to_char(turno.DataOraInizio,'yyyy-mm-dd hh24:mi'));
            gui.AggiungiElementoTabella(to_char(turno.DataOraFine,'yyyy-mm-dd hh24:mi'));
            gui.AggiungiElementoTabella(to_char(turno.DataOraInizioEff,'yyyy-mm-dd hh24:mi'));
            gui.AggiungiElementoTabella(to_char(turno.DataOraFineEff,'yyyy-mm-dd hh24:mi'));
            if(turno.DataOraInizio>(sysdate + interval '1' day)) THEN
            --si possono modificare/cancellare solo turni da dopo un giorno dalla data attuale
            gui.apriElementoPulsanti;
            gui.AggiungiPulsanteModifica(''||URL||'modificaTurno?'||
            'IDAutista='|| Turno.Matricola ||
            '&Taxi=' || turno.FK_Taxi ||
            '&DataInizio='|| to_char(Turno.DataOraInizio, 'yyyy-mm-dd hh24:mi') ||
            '&DataFine='|| to_char(Turno.DataOraFine, 'yyyy-mm-dd hh24:mi')||
            '&idSessione='||idSessione||'');
            gui.AggiungiPulsanteCancellazione(''''||URL||'eliminaTurno?'||
            'IDAutista='|| Turno.Matricola ||
            '&Taxi=' || turno.FK_Taxi||
            '&DataInizio='||  to_char(Turno.DataOraInizio, 'yyyy-mm-dd hh24:mi')||
            '&idSessione='||idSessione||''||'''');
            gui.chiudiElementoPulsanti;
            else
            gui.AggiungiElementoTabella(' ');
            end if;
            gui.chiudirigatabella;
        end LOOP;

        end if;
        gui.chiudiTabella;
        gui.aCapo(2);
    gui.chiudipagina;
    exception when others then gui.Reindirizza(''||URL||'visualizzazioneTurni?errore='||sqlerrm||
            '&idSessione='||idSessione||'''');
END visualizzazioneTurni;

procedure modificaTurno(
    IDAutista in Dipendenti.Matricola%TYPE default null,
    Taxi in Taxi.IDtaxi%TYPE default null,
    DataInizio  varchar2 default null,
    Datafine  varchar2 default null,
    errore varchar2 default null,
    idSessione varchar2 default null
) AS
    BEGIN
        gui.APRIPAGINA('modificaTurno',idSessione);
        --controllo diritti
        if SessionHandler.getRuolo(idSessione) <> 'Manager' THEN
            gui.AggiungiPopup(false, 'Non hai il permesso per visualizzare questa pagina!');
            gui.acapo(3);
            gui.bottoneaggiungi(testo => 'Ritorna alla home', url =>costanti.URL ||'gui.homepage?idSessione='||IDSessione||chr(38)||'p_success=S');
            gui.chiudipagina;
            return;
        end if;
        --visualizzo messaggi di errore
        if(errore is not null) then
        gui.AggiungiPopup(successo=>false,testo=>errore);
        gui.Acapo(2);
        end if;
        gui.aggiungiIntestazione(testo => 'Modifica Turni');
        gui.aCapo(2);
        gui.BottoneAggiungi(testo=>'Visualizza turni', url=>''||URL||'visualizzazioneTurni'||
            '?idSessione='||idSessione||''); 
        gui.aCapo;
        gui.aggiungiForm(url=>''||URL||'verificaModifica');

        gui.AggiungiLabel(target=>'',testo=>'Matricola');
        gui.Aggiungicampoform(nome => 'IDAutista',placeholder=>'Matricola',value=>IDAutista, classeicona=>'fa fa-id-badge');
        gui.AggiungiLabel(target=>'',testo=>'Taxi');
        gui.Aggiungicampoform(nome => 'Taxi', placeholder => 'Taxi',value=>Taxi, classeicona=>'fa fa-car');
        gui.AggiungiLabel(target=>'',testo=>'Data inizio');
        gui.Aggiungiinput(tipo => 'datetime-local', nome => 'DataInizio', placeholder => 'Inizio ',value=>DataInizio);
        gui.aCapo();
        gui.AggiungiLabel(target=>'',testo=>'Data fine');
        gui.Aggiungiinput(tipo => 'datetime-local', nome => 'DataFine', placeholder => 'Fine',value=>DataFine);
        --si passano per identificare un turno 
        gui.AggiungiCampoFormHidden(tipo => 'datetime-local', nome => 'DataInizioPrec',value=>DataInizio);
        gui.AggiungiCampoFormHidden( nome => 'IDPrec',value=>IDAutista);
        gui.AggiungiCampoFormHidden( nome => 'TaxiPrec',value=>Taxi);
        gui.AggiungiCampoFormHidden(tipo => 'datetime-local', nome => 'DataFinePrec',value=>DataFine);
        gui.AggiungiCampoformHidden(nome=>'idSessione',value=>idSessione);
        gui.aCapo(2);
        gui.Aggiungibottonesubmit(value=>'Modifica turno');
        gui.chiudiform;
        gui.ChiudiPagina;
        exception when others then gui.Reindirizza(''||URL||'modificaTurno?errore='||sqlerrm||''||
            '&idSessione='||idSessione||'');
END modificaTurno;


procedure verificaModifica(
    IDAutista in Dipendenti.Matricola%TYPE default null,
    Taxi in Taxi.IDtaxi%TYPE default null,
    DataInizioPrec varchar2 default null,
    IDPrec in Dipendenti.Matricola%type default null,
    TaxiPrec in Taxi.IDtaxi%type default null,
    DataFinePrec varchar2 default null,
    DataInizio  varchar2 default null,
    DataFine  varchar2 default null,
    idSessione varchar2 default null
) IS
inizio date;
fine date;
valido number(3);
disp number(3);
turno exception;
autista exception;
taxi_disp exception;
neop exception;
orari_non_validi exception;
dataPat date;
NeoPat number;
manager number;
    BEGIN
        --controllo i diritti
        if SessionHandler.getRuolo(idSessione) <> 'Manager' THEN
            gui.AggiungiPopup(false, 'Non hai il permesso per visualizzare questa pagina!');
            gui.acapo(3);
            gui.bottoneaggiungi(testo => 'Ritorna alla home', url =>costanti.URL ||'gui.homepage?idSessione='||IDSessione||chr(38)||'p_success=S');
            gui.chiudipagina;
            return;
        end if;
        manager:= SessionHandler.getidUser(idSessione);
        inizio:= to_date(replace(DataInizio,'T',' ' ),'yyyy-mm-dd hh24:mi');
        fine:=to_date(replace(DataFine,'T',' '),'yyyy-mm-dd hh24:mi');
        
        --controllare che gli orari inseriti siano validi
        if inizio>=fine or inizio<(sysdate +interval '1' day)  then
            raise orari_non_validi;

        -- il turno è maggiore di 6 ore o minore di 2
        elsif ((fine-inizio)*24)> 6 or (fine-inizio)*24<2 then 
            raise turno;                  
        end if;

        --controllo se l'autista ha una patente valida e non ha turni assegnati negli orari inseriti
        if (IDAutista<>IDPrec or DataInizio<>DataInizioPrec) then
            select Count(FK_Dipendente)
            into valido
            from autisti a
            join Dipendenti d on a.FK_DIPENDENTE=d.Matricola
            where FK_Dipendente=IDAutista and 
                a.FK_Dipendente in
                (select t.FK_Autista
                from turni t
                where (t.DataOraInizio < (fine + (2/24))
                and t.DataOraFine > (inizio -(2/24)))
                and t.DataOraInizio<>to_date(replace(DataInizioPrec,'T',' '),'yyyy-mm-dd hh24:mi'))
                or not exists (select *
                                from patenti p
                                where p.Validita=1);
            
            if valido>0  then raise autista;
            end if;
        end if;

        select DataPatente into DataPat 
        from autisti a
        where a.FK_Dipendente = IDAutista;
        --da quanti mesi l'autista è patentato
        NeoPat := months_between(sysdate,DataPat);

        --controllo se in taxi è disponibile e se l'autista è neopatentato la cilindrata
       if Taxi<>TaxiPrec or IDAutista<>IDPrec or DataInizio<>DataInizioPrec then
            select Count(IDTaxi)
            into disp
            from taxi ta 
            where IDTaxi=Taxi and (( NeoPat<12 and ta.Cilindrata>1400) or 
            ta.Stato='non disponibile' or
            ta.IDTaxi in
                (select tu.FK_Taxi
                from turni tu
                where (inizio -2/24)<tu.DataOraFine AND (Fine+2/24)>tu.DataOraInizio
                and tu.DataOraInizio<>to_date(replace(DataInizioPrec,'T',' '),'yyyy-mm-dd hh24:mi')) or
            ta.IDTaxi not in
                (select r.FK_Taxi
                from revisioni r
                where r.Scadenza>fine));
            
            if(disp>0) then
                if(Taxi<>TaxiPrec or DataInizio<>DataInizioPrec) then raise taxi_disp;
                elsif(IDAutista<>IDPrec and NeoPat<12) then raise neop;
                end if;
            end if;
        end if;

        update TURNI 
        set FK_Autista=IDAutista,
            FK_Taxi=Taxi,
            DataOraInizio=to_date(replace(DataInizio,'T', ' '), 'yyyy-mm-dd hh24:mi'),
            DataOraFine=to_date(replace(DataFine,'T', ' '), 'yyyy-mm-dd hh24:mi'),
            FK_Manager=manager
            where
            FK_Autista = IDPrec and
            FK_Taxi = TaxiPrec and
            DataOraInizio = to_date(replace(DataInizioPrec,'T',' '),'yyyy-mm-dd hh24:mi');
        gui.reindirizza(''||URL||'visualizzazioneTurni?successo= Turno modificato'||
            '&idSessione='||idSessione||'');
        gui.chiudipagina;

       Exception 
       when orari_non_validi then gui.Reindirizza(''||URL||'modificaTurno?'||
            'IDAutista='|| IDPrec ||
            '&Taxi=' || TaxiPrec ||
            '&DataInizio='|| DataInizioPrec ||
            '&DataFine='|| DataFinePrec||'&errore=Orari inseriti non validi'||
            '&idSessione='||idSessione||'');
        when turno then gui.Reindirizza(''||URL||'modificaTurno?'||
            'IDAutista='|| IDPrec ||
            '&Taxi=' || TaxiPrec ||
            '&DataInizio='|| DataInizioPrec ||
            '&DataFine='|| DataFinePrec||'&errore=Turno superiore a 6 ore o inferiore a 2'||
            '&idSessione='||idSessione||'');
        when autista then gui.Reindirizza(''||URL||'modificaTurno?'||
            'IDAutista='|| IDPrec ||
            '&Taxi=' || TaxiPrec ||
            '&DataInizio='|| DataInizioPrec ||
            '&DataFine='|| DataFinePrec||'&errore=Autista non valido'||
            '&idSessione='||idSessione||'');
        when taxi_disp then gui.Reindirizza(''||URL||'modificaTurno?'||
            'IDAutista='|| IDPrec ||
            '&Taxi=' || TaxiPrec ||
            '&DataInizio='|| DataInizioPrec ||
            '&DataFine='|| DataFinePrec||'&errore=Taxi non valido'||
            '&idSessione='||idSessione||'');
            when neop then gui.Reindirizza(''||URL||'modificaTurno?'||
            'IDAutista='|| IDPrec ||
            '&Taxi=' || TaxiPrec ||
            '&DataInizio='|| DataInizioPrec ||
            '&DataFine='|| DataFinePrec||'&errore=Autista neopatentato'||
            '&idSessione='||idSessione||'');
        when others then gui.Reindirizza(''||URL||'modificaTurno?'||
            'IDAutista='|| IDPrec||
            '&Taxi=' || TaxiPrec ||
            '&DataInizio='|| DataInizioPrec ||
            '&DataFine='|| DataFinePrec||'&errore='||sqlerrm||''||
            '&idSessione='||idSessione||'');
         
END verificaModifica;

procedure eliminaTurno(
    IDAutista in Turni.FK_Autista%TYPE default null,
    Taxi in Taxi.IDtaxi%TYPE default null,
    DataInizio  varchar2 default null,
    idSessione varchar2 default null
) IS
errore exception;
    BEGIN
        --controllo diritti
        if SessionHandler.getRuolo(idSessione) <> 'Manager' THEN
            gui.AggiungiPopup(false, 'Non hai il permesso per visualizzare questa pagina!');
            gui.acapo(3);
            gui.bottoneaggiungi(testo => 'Ritorna alla home', url =>costanti.URL ||'gui.homepage?idSessione='||IDSessione||chr(38)||'p_success=S');
            gui.chiudipagina;
            return;
        end if;
        --turno previsto tra meno di 24 ore o già passato
        if(to_date(DataInizio,'yyyy-mm-dd hh24:mi')<sysdate + interval '1' day) then raise errore;
        end if;

        DELETE FROM TURNI t
        WHERE
            t.FK_Autista = IDAutista and
            t.FK_Taxi = Taxi and
            t.DataOraInizio = to_date(DataInizio,'yyyy-mm-dd hh24:mi');
        gui.reindirizza(''||URL||'visualizzazioneTurni?successo=Turno eliminato'||
            '&idSessione='||idSessione||'');

        Exception
        when errore then gui.reindirizza(''||URL||'visualizzazioneTurni?errore= non è possibile cancellare il turno'||
            '&idSessione='||idSessione||'');
        when others then gui.reindirizza(''||URL||'visualizzazioneTurni?errore= '||sqlerrm||''||
            '&idSessione='||idSessione||'');
END eliminaTurno;

procedure inserimentoTurni(
    IDAutista in Turni.FK_Autista%TYPE default null,
    Taxi in Taxi.IDtaxi%TYPE default null,
    DataInizio  varchar2 default null,
    Datafine  varchar2 default null,
    errore varchar2 default null,
    idSessione varchar2 default null
) AS
elementi gui.StringArray;
--array per visualizzare matricola, nome e cognome di un autista nel form
aut gui.StringArray := gui.StringArray();
--array per il campo da mandare al submit del form
matr gui.StringArray := gui.StringArray();
--array per id del taxi 
tax gui.StringArray := gui.StringArray();
--array per data scadenza revisione
revis gui.StringArray := gui.StringArray();
DataPat date;
Neopat number;
inizio date;
fine date;
tutto varchar2(100);
rev varchar(1000);
orari exception;
turno exception;
giorno exception;
valore date;
manager number;
    BEGIN    
        gui.APRIPAGINA('Inserisci Turni',idSessione); 
        --controllo i diritti 
        if SessionHandler.getRuolo(idSessione) <> 'Manager' THEN
            gui.AggiungiPopup(false, 'Non hai il permesso per visualizzare questa pagina!');
            gui.acapo(3);
            gui.bottoneaggiungi(testo => 'Ritorna alla home', url =>costanti.URL ||'gui.homepage?idSessione='||IDSessione||chr(38)||'p_success=S');
            gui.chiudipagina;
            return;
        end if;
        --visualizzo messaggi di errore
        if(errore is not null) then
        gui.AggiungiPopup(successo=>false,testo=>errore);
        gui.Acapo(2);
        end if;
        gui.aggiungiIntestazione(testo => 'Inserimento Turni');
        gui.aCapo(2);
    
        gui.BottoneAggiungi(testo=>'Visualizza turni', url=>''||URL||'visualizzazioneTurni'||
            '?idSessione='||idSessione||''); 
        gui.aCapo;
        inizio:= to_date(replace(DataInizio,'T',' ' ),'yyyy-mm-dd hh24:mi');
        fine:=to_date(replace(DataFine,'T',' '),'yyyy-mm-dd hh24:mi');
        if (IDAutista is null and Taxi is null and DataInizio is null and DataFine is NULL)
        OR (IDAutista is not null and Taxi is not null and DataInizio is not null and DataFine is not null)
        then       

        elementi := gui.StringArray('Data Inizio', 'Data Fine', ' ');      
        
        --si effettua l'insert
        if(IDAutista is not null and Taxi is not null and DataInizio is not null and DataFine is not null)
        then
         manager := SessionHandler.getIDuser(idSessione);
          insert into turni (FK_Manager,FK_Autista,FK_Taxi, DataOraInizio,DataOraFine)
          values (manager,IDAutista, Taxi, inizio, fine);
          gui.AGGIUNGIPOPUP(true,testo=>'Turno inserito con successo');
        end if;
        gui.aCapo;
        
        --permette di inserire gli orari
        gui.aggiungiForm(url=>''||URL||'inserimentoTurni');
        gui.aggiungiIntestazione(testo => 'Inserisci orario', dimensione=>'h1');
        gui.AggiungiLabel(target=>'',testo=>'Data inizio');
        gui.AggiungiInput(tipo => 'datetime-local', nome => 'DataInizio', placeholder => 'Inizio ');       
        gui.AggiungiLabel(target=>'',testo=>'Data fine');
        gui.AggiungiInput(tipo => 'datetime-local', nome => 'DataFine', placeholder => 'Fine');        
        gui.AggiungiCampoformHidden(nome=>'idSessione',value=>idSessione);
        gui.acapo(2);
        gui.aggiungiBottoneSubmit(value=>'Avanti');

        gui.chiudiForm;

        elsif IDAutista is null and Taxi is null and DataInizio is not null and DataFine is not null
        then    elementi := gui.StringArray('IDAutista', 'Taxi','Data Inizio', 'Data Fine', ' ');
        gui.aCapo;

        --controllo se gli orari inseriti sono validi
        if inizio<(sysdate + interval '1' day) then 
           raise giorno;

        elsif inizio>=fine  then
            raise orari;

        -- il turno è maggiore di 6 ore o minore di 2
        elsif ((fine-inizio)*24)> 6 or ((fine-inizio)*24)< 2 then 
            raise turno;                  
        end if;

        --visualizzo autisti con la patente valida, senza turni nelle 2 ore precedenti/successive di inizio e fine turno
        for autista in 
        (select *
        from autisti a
        join Dipendenti d on a.FK_DIPENDENTE=d.Matricola
         where a.FK_Dipendente not in
            (select t.FK_Autista
            from turni t
            where (t.DataOraInizio < (fine + (2/24))
            and t.DataOraFine > (inizio -(2/24))))
            and exists (select *
                            from patenti p
                            where p.Validita=1))
        LOOP
         aut.EXTEND;
         matr.EXTEND;
         tutto := autista.FK_Dipendente||' '||autista.Nome||' '||autista.Cognome;
         aut(aut.LAST) := (tutto);
         --valori effettivi da passare al form          
         matr(matr.LAST) := (autista.FK_Dipendente);
        END LOOP;
        gui.aggiungiForm(url=>''||URL||'inserimentoTurni');
        gui.aggiungiGruppoInput;
        gui.AggiungiLabel(target=>'',testo=>'Data inizio');
        gui.AggiungiInput(tipo => 'datetime-local', nome => 'DataInizio', value => DataInizio, readonly=> True);
        gui.aCapo;
        gui.AggiungiLabel(target=>'',testo=>'Data fine');
        gui.AggiungiInput(tipo => 'datetime-local', nome => 'DataFine', value => DataFine, readonly=>True);
        gui.aCapo;
        gui.aggiungiSelezioneSingola(elementi=>aut, valoreEffettivo=>matr ,titolo=>'seleziona autista', ident=> 'IDAutista');
        gui.AggiungiCampoformHidden(nome=>'idSessione',value=>idSessione);
        gui.chiudiGruppoInput;
        gui.aggiungiBottoneSubmit(value=>'Avanti');
        
        gui.aCapo;
        gui.chiudiForm;
        
        elsif(IDAutista is not null and Taxi is null and DataInizio is not null and DataFine is not null)
        then
        elementi := gui.StringArray('IDAutista', 'Taxi','Data Inizio', 'Data Fine', ' ');
      
        gui.aCapo;
        
        select DataPatente into DataPat 
        from autisti a
        where a.FK_Dipendente = IDAutista;

        --da quanti mesi l'autista ha la patente
        NeoPat := months_between(sysdate,DataPat);

       --visualizzo taxi disponibili, con revisione valida e che l'autista è abilitato a guidare
        for taxi in 
        (select *
        from taxi ta 
        join Revisioni r on ta.IDTaxi=r.FK_Taxi
        where ( NeoPat>12 or ta.Cilindrata < 1400) and
             r.Scadenza>fine and
             ta.Stato<>'non disponibile' and
             ta.IDTaxi not in
            (select tu.FK_Taxi
            from turni tu
            where (inizio -2/24)<tu.DataOraFine AND (Fine+2/24)>tu.DataOraInizio 
            ))
        LOOP
          tax.EXTEND;
          revis.EXTEND;
          rev := taxi.IDTAXI||' Scadenza :'|| taxi.Scadenza;
          revis(revis.LAST) := (rev);
          tax(tax.LAST) := (taxi.IDtaxi);
        END LOOP;

        gui.aggiungiForm(url=>''||URL||'inserimentoTurni');
        gui.aggiungiGruppoInput; 
        gui.AggiungiLabel(target=>'',testo=>'Data inizio');
        gui.AggiungiInput(tipo => 'datetime-local', nome => 'DataInizio', value => DataInizio, readonly=>true);
        gui.aCapo; 
        gui.AggiungiLabel(target=>'',testo=>'Data fine');
        gui.AggiungiInput(tipo => 'datetime-local', nome => 'DataFine', value => DataFine,readonly=>True);
        gui.aCapo;
        gui.aggiungiLabel(target=>'',testo=>'ID Autista');
        gui.AggiungiInput(tipo =>'text', nome =>'IDAutista', value=> IDAutista, readonly=>True);
        gui.aCapo;
        gui.aggiungiSelezioneSingola(elementi=>revis, valoreEffettivo=>tax, titolo=>'seleziona taxi', ident=> 'Taxi');
        gui.AggiungiCampoformHidden(nome=>'idSessione',value=>idSessione);
        gui.chiudiGruppoInput;
        gui.aCapo;
        gui.aggiungiBottoneSubmit(value=>'Inserisci turno');
        gui.chiudiForm;
        

        else 
        gui.reindirizza(''||URL||'inserimentoTurni');
        end if;
        gui.ChiudiPagina;
    
    exception 
    when orari then gui.Reindirizza(''||URL||'inserimentoTurni?errore= Orari inseriti non corretti'||
            '&idSessione='||idSessione||'');
    when turno then gui.Reindirizza(''||URL||'inserimentoTurni?errore= Il turno deve durare da 2 a 6 ore'||
            '&idSessione='||idSessione||'');
    when giorno then 
    valore:= sysdate+ interval '1' day;
    gui.Reindirizza(''||URL||'inserimentoTurni?errore='|| 'Si possono inserire turni dal '||valore||
            '&idSessione='||idSessione||'');
    when others then gui.Reindirizza(''||URL||'inserimentoTurni?errore='||sqlerrm||
            '&idSessione='||idSessione||'');

END inserimentoTurni;

procedure turniAutista(
    Taxi in Taxi.IDtaxi%TYPE default null,
    DataInizio  varchar2 default null,
    errore varchar2 default null,
    successo varchar2 default null,
    idSessione varchar2 default null
) AS
    IDAutista number;
    elementi gui.StringArray;
    inizio date;
    BEGIN
        elementi := gui.StringArray('Taxi','Data Inizio', 'Data Fine', 'Inizio Effettivo', 'Fine Effettivo',' ');
        gui.APRIPAGINA('Turno Autista',idSessione); 
        --controllo i diritti
        if SessionHandler.getRuolo(idSessione) <> 'Autista' THEN
            gui.AggiungiPopup(false, 'Non hai il permesso per visualizzare questa pagina!');
            gui.acapo(3);
            gui.bottoneaggiungi(testo => 'Ritorna alla home', url =>costanti.URL ||'gui.homepage?idSessione='||IDSessione||chr(38)||'p_success=S');
            gui.chiudipagina;
            return;
        end if;
        --visualizzo messaggi di errore o successo
        if(errore is not null) then
        gui.AggiungiPopup(successo=>false,testo=>errore);
        gui.Acapo(2);
        elsif(successo is not null) then 
        gui.AggiungiPopup(successo=>true,testo=>successo);
        gui.aCapo(2);
        end if;

        gui.aggiungiIntestazione(testo => 'Turni autista');
        gui.aCapo(2);
        gui.ApriFormFiltro(''||URL||'turniAutista');

        gui.AggiungiCampoFormFiltro(nome => 'Taxi', placeholder => 'Taxi');
        gui.AggiungiCampoFormFiltro(tipo => 'datetime-local', nome => 'DataInizio', placeholder => 'Inizio ');
        gui.AggiungiCampoformHidden(nome=>'idSessione',value=>idSessione);
        gui.AGGIUNGICAMPOFORMFILTRO('submit','','','filtra');
        gui.CHIUDIFORMFILTRO;

        gui.aCapo;

        IDAutista := SessionHandler.getIDuser(idSessione);
        --se non specificato visualizzo i turni da 8 ore prima l'orario attuale
        inizio:=sysdate - interval '8' hour;
        if DataInizio is not null then
             inizio := TO_DATE(replace(DataInizio,'T',' '), 'yyyy-mm-dd hh24:mi');
       end if;

        gui.APRITABELLA(elementi);

        for turno IN
        (SELECT t.FK_Taxi, t.DataOraInizio, t.DataOraFine, t.DataOraInizioEff, t.DataOraFineEff 
        FROM Turni t 
        JOIN Autisti a ON a.FK_DIPENDENTE = t.FK_AUTISTA
        JOIN Dipendenti d ON d.Matricola = a.FK_DIPENDENTE
        WHERE 
            (Taxi IS NULL OR t.FK_Taxi = trim(Taxi)) AND
            (t.DataOraInizio > inizio) and 
            (d.Matricola=trim(IDAutista))
        order by t.DataOraInizio)
        
        LOOP
                gui.AGGIUNGIRIGATABELLA;
                
                gui.AggiungiElementoTabella(turno.FK_Taxi);
                gui.AggiungiElementoTabella(to_char(turno.DataOraInizio,'yyyy-mm-dd hh24:mi'));
                gui.AggiungiElementoTabella(to_char(turno.DataOraFine,'yyyy-mm-dd hh24:mi'));
                gui.AggiungiElementoTabella(to_char(turno.DataOraInizioEff,'yyyy-mm-dd hh24:mi'));
                gui.AggiungiElementoTabella(to_char(turno.DataOraFineEff,'yyyy-mm-dd hh24:mi'));
                --pulsanti inizio e fine effettivi se turno da dopo 2 ore l'orario di fine e prima di 15 minuti l'orario si inizio se non gia inseriti 
                if (turno.DataOraFine>(sysdate - interval '2' hour) and turno.DataOraInizio<(sysdate + interval '15' minute)  and turno.DataOraFineEff is null ) then
                    gui.apriElementoPulsanti;
                    gui.AggiungiPulsanteGenerale(collegamento=>''''||URL||'inizioTurno?'||
                    'IDAutista='|| IDAutista ||
                    '&Taxi=' || turno.FK_Taxi||
                    '&DataInizio='||  to_char(Turno.DataOraInizio, 'yyyy-mm-dd hh24:mi')||
                    '&DataFine='|| to_char(Turno.DataOraFine, 'yyyy-mm-dd hh24:mi')||
                    '&idSessione='||idSessione||'''',testo=>'Inizio turno');

                    gui.AggiungiPulsanteGenerale(collegamento=>''''||URL||'fineTurno?'||
                    'IDAutista='|| IDAutista ||
                    '&Taxi=' || turno.FK_Taxi||
                    '&DataInizioEff='|| to_char(turno.DataOraInizioEff,'yyyy-mm-dd hh24:mi')||
                    '&DataFine='||  to_char(Turno.DataOraFine, 'yyyy-mm-dd hh24:mi')||
                    '&idSessione='||idSessione||'''',testo=>'Fine turno');
                    gui.chiudiElementoPulsanti;
                else
                gui.AGGIUNGIELEMENTOTABELLA(' ');
                end if;
                gui.chiudirigatabella;
        end loop;
        
        gui.chiudiTabella;
        gui.aCapo(2);
    gui.chiudipagina;
    exception when others then gui.Reindirizza(''||URL||'turniAutista?errore='||sqlerrm||'&idSessione='||idSessione||'');
END turniAutista;

procedure inizioTurno(
    IDAutista in Dipendenti.Matricola%TYPE default null,
    Taxi in Taxi.IDtaxi%TYPE default null,
    DataInizio  varchar2 default null,
    DataFine varchar2 default null,
    idSessione varchar2 default null
) IS
inizio date;
inizioEff date;
fine date;
prova number;
troppo_presto exception;
troppo_tardi exception;
    BEGIN
        --controllo i diritti
        if SessionHandler.getRuolo(idSessione) <> 'Autista' THEN
            gui.apriPagina('errore',idSessione);
            gui.AggiungiPopup(false, 'Non hai il permesso per questa azione!');
            gui.acapo(3);
            gui.bottoneaggiungi(testo => 'Ritorna alla home', url =>costanti.URL ||'gui.homepage?idSessione='||IDSessione||chr(38)||'p_success=S');
            gui.chiudipagina;
        end if;
        inizio:= to_date(replace(DataInizio,'T',' ' ),'yyyy-mm-dd hh24:mi');     
        inizioEff:= SYSDATE;
        fine:= (to_date(replace(DataFine,'T',' ' ),'yyyy-mm-dd hh24:mi'));

        --se l'inizio effettivo è 15 minuti prima dell'inizio previsto
        if (inizioEff<inizio and (((inizio-inizioEff)*24*60)>15))  then 
        raise troppo_presto;
        
        --se l'inizio effettivo è minore dell'inizio previsto di meno di 15 minuti
        elsif(inizioEff<inizio) and (inizio-inizioEff)*24*60<=15 then
        --si inserisce l'orario di inizio previsto
          inizioEff:=inizio;

        --se inizia il turno dopo l'orario di fine prevista
        elsif inizioEff>fine then
        raise troppo_tardi;
        end if;

        update TURNI 
        set 
            DataOraInizioEff=inizioEff
            where
            FK_Autista = IDAutista and
            FK_Taxi = Taxi and
            DataOraInizio = inizio and
            DataOraInizioEff is null;

            gui.reindirizza(''||URL||'turniAutista?successo=Inizio inserito con successo'||
            '&idSessione='||idSessione||'');     
        Exception
        when troppo_presto then  gui.reindirizza(''||URL||'turniAutista?errore=Non è ancora il momento di iniziare'||
            '&idSessione='||idSessione||'');
        when troppo_tardi then gui.reindirizza(''||URL||'turniAutista?errore=Il turno è già passato'||
            '&idSessione='||idSessione||'');
        when others then gui.Reindirizza(''||URL||'turniAutista?errore='||sqlerrm||''||
            '&idSessione='||idSessione||'');
END inizioTurno;

procedure fineTurno(
    IDAutista in Dipendenti.Matricola%TYPE default null,
    Taxi in Taxi.IDtaxi%TYPE default null,
    DataInizioEff varchar2 default null,
    DataFine  varchar2 default null,
    idSessione varchar2 default null
) IS
fine date;
fineEff date;
turno_non_iniziato exception;
tardi exception;
    BEGIN
        --controllo i diritti
        if SessionHandler.getRuolo(idSessione) <> 'Autista' THEN
            gui.apriPagina('errore',idSessione);
            gui.AggiungiPopup(false, 'Non hai il permesso per questa azione!');
            gui.acapo(3);
            gui.bottoneaggiungi(testo => 'Ritorna alla home', url =>costanti.URL ||'gui.homepage?idSessione='||IDSessione||chr(38)||'p_success=S');
            gui.chiudipagina;
        end if;
        fine:= to_date(replace(Datafine,'T',' ' ),'yyyy-mm-dd hh24:mi');     
        fineEff:=SYSDATE;

        --se il turno non è iniziato
        if (DataInizioEff is null) then
            raise turno_non_iniziato; 

        --inserisce la fine effettiva due ore dopo l'ora prevista
        elsif fine<fineEff and ((fineEff-fine)*24)>2 then 
            raise tardi;
        end if;
        
        update TURNI 
        set 
            DataOrafineEff=fineEff
            where
            FK_Autista = IDAutista and
            FK_Taxi = Taxi and
            DataOrafine = fine and
            DataOraFineEff is null;
        gui.reindirizza(''||URL||'turniAutista?successo= Fine inserita con successo'||
            '&idSessione='||idSessione||'');
    exception
    when turno_non_iniziato then gui.reindirizza(''||URL||'turniAutista?errore= Turno non iniziato'||
            '&idSessione='||idSessione||'');
    when tardi then gui.reindirizza(''||URL||'turniAutista?errore=Turno già finito'||
            '&idSessione='||idSessione||'');
    when others then gui.Reindirizza(''||URL||'turniAutista?errore='||sqlerrm||''||
            '&idSessione='||idSessione||'');
         
end fineTurno;

procedure mediaTurni(
    noman in Dipendenti.Nome%Type default null,
    cogman in Dipendenti.Cognome%type default null,
    sesman varchar2 default '',
    nomaut in Dipendenti.Nome%type default null,
    cogaut in Dipendenti.Cognome%type default null,
    sesaut varchar2 default '',
    errore varchar2 default null,
    idSessione varchar2 default null
) AS
    i number := 0;
    totale number :=0;
    totaut number:=0;
    n_aut varchar(100);
    c_aut varchar(100);
    totore number;
    mindata date;
    maxdata date;
    maxturni number;
    mediaT number;
    mediaOre number;
    elementi gui.StringArray:= gui.StringArray();
    BEGIN
        gui.APRIPAGINA('Media Turni',idSessione);
        if SessionHandler.getRuolo(idSessione) <> 'Manager' THEN
            gui.AggiungiPopup(false, 'Non hai il permesso per visualizzare questa pagina!');
            gui.acapo(3);
            gui.bottoneaggiungi(testo => 'Ritorna alla home', url =>costanti.URL ||'gui.homepage?idSessione='||IDSessione||chr(38)||'p_success=S');
            gui.chiudipagina;
            return;
        end if;
        if(errore is not null) then
        gui.AggiungiPopup(successo=>false,testo=>errore);
        gui.Acapo(2);
        end if;
    
        select avg(totMan)
        into mediaT
        from TurniMan;

        select avg(ore)
        into mediaOre
        from TurniMan;

        gui.aggiungiIntestazione(testo => 'Media numero turni assegnati da un manager: '||trunc(mediaT,2)||'');
        gui.aggiungiIntestazione(testo=> 'Media ore assegnate: '||trunc(mediaOre*24,2)||'');
        gui.aCapo();

        select avg(numTurni)
        into mediaT
        from migaut;
        gui.AGGIUNGIINTESTAZIONE('Media turni svolti da un autista: '||trunc(mediaT,2)||'', dimensione=>'h3');

        select max(numTurni)
        into maxturni
        from MigAut;
        gui.AGGIUNGIINTESTAZIONE('Massimo numero di turni svolti da un autista: '||maxturni||'', dimensione=>'h3');

       for a in
        (select autista, numTurni 
        from MigAut m
        where numTurni=maxturni)
        loop
         select nome, cognome
         into n_aut, c_aut
         from dipendenti
         where matricola=a.autista;         
         gui.aggiungiparagrafo('Autisti con più turni svolti: '||n_aut||' '||c_aut||'');
        end loop;
        gui.acapo();

        select avg(oreTurni)
        into mediaOre
        from migaut;
        gui.AGGIUNGIINTESTAZIONE('Media numero ore svolte da un autista: '||trunc(mediaOre*24,2)||'', dimensione=>'h3');

        select max(oreTurni)
        into maxturni
        from MigAut;
        gui.AGGIUNGIINTESTAZIONE('Massimo numero di ore lavorate da un autista: '||maxturni*24||'', dimensione=>'h3');
        
       for a in
        (select autista, oreTurni 
        from MigAut m
        where oreTurni=maxturni)
        loop
         select nome, cognome
         into n_aut, c_aut
         from dipendenti
         where matricola=a.autista;         
         gui.aggiungiparagrafo('Autisti con più ore lavorate: '||n_aut||' '||c_aut||'');
        end loop;
        elementi := gui.StringArray('Nome Autista','Turni assegnati','Totale ore', 'Data primo turno','Data ultimo turno');


         gui.ApriFormFiltro(''||URL||'mediaTurni');

        gui.AGGIUNGICAMPOFORMFILTRO(nome=>'noman',placeholder=>'Nome Manager'); 
        gui.AggiungiCampoFormFiltro(nome => 'cogman', placeholder => 'Cognome Manager');
        gui.ApriSelectFormFiltro(nome => 'sesman', placeholder => 'Sesso Manager');
        gui.aggiungiOpzioneselect('', sesman='', 'Tutti');
        gui.aggiungiOpzioneselect('N', sesman='N', 'Non Specificato');
        gui.aggiungiOpzioneselect('M', sesman='M', 'Maschio');
        gui.aggiungiOpzioneselect('F', sesman='F', 'Femmina');
        gui.chiudiSelectFormFiltro;
        gui.AggiungiCampoFormFiltro(nome => 'nomaut', placeholder => 'Nome Autista');
        gui.AggiungiCampoFormFiltro(nome => 'cogaut', placeholder => 'Cognome Autista');
        gui.ApriSelectFormFiltro(nome => 'sesaut', placeholder => 'Sesso Autista');
        gui.aggiungiOpzioneselect('N', sesaut='N', 'Non Specificato');
        gui.aggiungiOpzioneselect('M', sesaut='M', 'Maschio');
        gui.aggiungiOpzioneselect('F', sesaut='F', 'Femmina');
        gui.chiudiSelectFormFiltro;
        gui.AggiungiCampoformHidden(nome=>'idSessione',value=>idSessione);
        gui.AggiungiCampoFormFiltro('submit', '', '', 'filtra');
        gui.chiudiFormFiltro;
        gui.aCapo;

        --numero di turni nel database
        select count(*)
        into totale
        from turni;

        for m in 
        (select manager,totMan, ore,d.nome,d.cognome
        from TurniMan t
        join Dipendenti d on t.manager=d.Matricola
        where (noman is null or lower(d.Nome) like '%'||trim(lower(noman))||'%') and
        (cogman is null or lower(d.Cognome) like '%'||trim(lower(cogman))||'%') and
        (sesman is null or d.Sesso=sesman)
        order by ore desc)
        loop
            gui.aggiungiintestazione(m.nome||' '||m.cognome||'' , dimensione=>'h1');
            gui.aggiungiintestazione('Percentuale turni assegnati in totale: '||trunc((m.totMan/totale)*100,2)||'%'|| ' Ore: '||trunc(m.ore*24,2)||'');
            gui.aCapo();
            if m.totMan<>0 then
            i:=i+1; 
            gui.apritabella(elementi,ident=>i); 
            --autisti a cui il manager ha assegnato i turni                    
            for aut in
            (select d.Matricola,d.nome,d.cognome
            from autisti a
            join dipendenti d on a.FK_Dipendente=d.Matricola
            where (nomaut is null or lower(d.Nome) like '%'||trim(lower(nomaut))||'%') and
                  (cogaut is null or lower(d.Cognome) like '%'||trim(lower(cogaut))||'%') and
                  (sesaut is null or d.Sesso=sesaut))
            loop
                --totale ore di turni assegnati da un determinato manager a un determinato autista 
                --prima e ultima data di assegnazione di un turno
                select count(*),sum(DataOraFine-DataOraInizio), min(DataOraInizio), max(DataOraInizio)
                into totaut, totore, mindata, maxdata
                from turni
                where FK_Manager=m.manager and
                        FK_Autista=aut.Matricola;
                if(totaut<>0) then
                gui.aggiungirigatabella;
                gui.aggiungielementotabella(aut.nome||' '||aut.cognome);
                gui.aggiungielementotabella(totaut);
                gui.aggiungielementotabella((trunc(totore*24,2)));
                gui.aggiungielementotabella(to_char(mindata));
                gui.aggiungielementotabella(to_char(maxdata));
                gui.chiudirigatabella; 
                end if;                 
            end loop;  
            gui.chiuditabella(ident=>i);  
            end if; 
            gui.aCapo(2);
        end loop;
        gui.chiuditabella; 
        gui.ChiudiPagina;
        exception when others then gui.Reindirizza(''||URL||'mediaTurni?errore='||sqlerrm||
            '&idSessione='||idSessione||'');
END mediaTurni;

END Gruppo4;
