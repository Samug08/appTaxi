--SET DEFINE OFF;

create or replace package BODY  gruppo1 AS
-----------------------------------Leonardi----------------------------------------------------------------------------------------------------------------------------
    PROCEDURE visPren(
        p_id in PRENOTAZIONI.IDprenotazione%TYPE default null,
        p_data_min varchar2 default null,
        p_data_max varchar2 default null,
        p_ora_min varchar2 default null,
        p_ora_max varchar2 default null,
        p_partenza in PRENOTAZIONI.LuogoPartenza%TYPE default null,
        p_persone in PRENOTAZIONI.Npersone%TYPE default null,
        p_arrivo in PRENOTAZIONI.LuogoArrivo%TYPE default null,
        p_stato in PRENOTAZIONI.Stato%TYPE default null,
        p_durata in PRENOTAZIONI.Durata%TYPE default null,
        p_modificata in PRENOTAZIONI.Modificata%TYPE default null,
        p_tipo in NONANONIME.TIPO%TYPE default null,
        p_categoria in varchar2  default null,
        p_idCliente in CLIENTI.IDCLIENTE%TYPE DEFAULT NULL,
        p_targa     in taxi.targa%type default null,
        p_visPrenBoolean in integer default null,
        p_idSess in SESSIONICLIENTI.IDSESSIONE%TYPE DEFAULT NULL)
    is
    head gui.StringArray;
    optionals gui.StringArray := gui.StringArray();
    Convenzioni gui.StringArray := gui.StringArray();
    isCumulabile boolean;
    ruolo varchar2(10);


begin
    ruolo:=SESSIONHANDLER.GETRUOLO(p_idSess);
    case ruolo
        when 'Cliente' then
            head := gui.StringArray('Codice', 'Luogo di Partenza', 'Data di Partenza', 'Ora di Partenza', 'Luogo di Arrivo', 'Persone', 'Modificata','Stato','Durata','tipo','categoria','Convenzioni','azioni');
            gui.APRIPAGINA('VisualizzaPrenotazioniCliente', p_idSess);
            gui.AGGIUNGIINTESTAZIONE('Visualizza le tue prenotazioni','h1');
        when 'Operatore'  then
            head := gui.StringArray('Codice', 'Luogo di Partenza', 'Data di Partenza', 'Ora di Partenza', 'Luogo di Arrivo', 'Persone', 'Modificata','Stato','Durata','tipo','categoria','Convenzioni', 'Cliente','Taxi','azioni');
            gui.APRIPAGINA('VisualizzaPrenotazioniOperatore', p_idSess);
            gui.AGGIUNGIINTESTAZIONE('Visualizza tutte le prenotazioni','h1');
         when 'Manager'  then
            head := gui.StringArray('Codice', 'Luogo di Partenza', 'Data di Partenza', 'Ora di Partenza', 'Luogo di Arrivo', 'Persone', 'Modificata','Stato','Durata','tipo','categoria','Convenzioni', 'Cliente','Taxi');
            gui.APRIPAGINA('VisualizzaPrenotazioniOperatore', p_idSess);
            gui.AGGIUNGIINTESTAZIONE('Visualizza tutte le prenotazioni','h1');
        else
            RAISE NoPermessi;
    end case;
    gui.ACAPO;
    if p_visPrenBoolean is not null then
        case  p_visPrenBoolean
            when 0 then
                gui.AGGIUNGIPOPUP(true, 'Prenotazione standard inserita.');
            when 1 then
                gui.AGGIUNGIPOPUP(true, 'Prenotazione di lusso inserita.');
            when 2 then
                gui.AGGIUNGIPOPUP(true, 'Prenotazione accessibile inserita.');
            when 3 then
                gui.AGGIUNGIPOPUP(true,'Prenotazione annullata con successo.');
            when 4 then
                gui.AGGIUNGIPOPUP(false,'La prenotazione non può più essere annullata.');
            when 5 then
                gui.AGGIUNGIPOPUP(true, 'La prenotazione è stata modificata con successo.');
            when 6 then
                gui.AGGIUNGIPOPUP(false, 'La prenotazione non è stata modificata perchè nessun dato è stato modificato.');
            when 7 then
                gui.AGGIUNGIPOPUP(true, 'Il taxi è stato assegnato correttamente alla prenotazione.');
            when 8 then
                gui.AGGIUNGIPOPUP(false, 'Impossibile modificare prenotazioni è annullata o rifiutata.');
            when 9 then
                gui.AggiungiPopup(false, 'Impossibile modificare prenotazioni passate.');
            when 10 then
                gui.AggiungiPopup(false, 'Impossibile modificare la prenotazione dopo l'||chr(39)|| 'orario consentito.');
            when 11 then
                gui.AggiungiPopup(false, 'Impossibile modificare prenotazioni già modificate.');
            else
                gui.AGGIUNGIPOPUP(false, 'errore inserimento prenotazione');
        end case;
        gui.ACAPO();
    end if;

    --inserimento dati filtro
    gui.ApriFormFiltro(u_root||'.visPren');
    gui.AggiungiCampoFormFiltro('number', 'p_id', p_id, 'Codice', minimo=>0 );
    gui.AggiungiCampoFormFiltro('text', 'p_partenza', p_partenza, 'Luogo di Partenza');
    gui.AggiungiCampoFormFiltro('text', 'p_arrivo', p_arrivo, 'Luogo di Arrivo');
    gui.AggiungiCampoFormFiltro('number', 'p_durata', p_durata, 'Durata', minimo=>1);

    gui.AGGIUNGIRIGATABELLA();

    gui.AggiungiCampoFormFiltro('date', 'p_data_min', p_data_min, 'data a partire da');
    gui.AggiungiCampoFormFiltro('date', 'p_data_max', p_data_max, 'data fino a');
    gui.AggiungiCampoFormFiltro('time', 'p_ora_min', p_ora_min, 'ora a partire da');
    gui.AggiungiCampoFormFiltro('time', 'p_ora_max', p_ora_max, 'ora fino a');

    gui.AGGIUNGIRIGATABELLA();
    gui.AggiungiCampoFormFiltro('number', 'p_persone', p_persone, 'Persone', minimo=>1);

    gui.APRISELECTFORMFILTRO('p_modificata','modificata');
    gui.AGGIUNGIOPZIONESELECT(0, case p_modificata when 0 then true else false end, 'non modificata');
    gui.AGGIUNGIOPZIONESELECT(1, case p_modificata when 1 then true else false end, 'modificata');
    gui.CHIUDISELECTFORMFILTRO;

    gui.APRISELECTFORMFILTRO('p_stato', 'stato');
    gui.AGGIUNGIOPZIONESELECT('accettata', case p_stato when 'accettata' then true else false end, 'accettata');
    gui.AGGIUNGIOPZIONESELECT('pendente', case p_stato when 'pendente' then true else false end, 'pendente');
    gui.AGGIUNGIOPZIONESELECT('rifiutata', case p_stato when 'rifiutata' then true else false end, 'rifiutata');
    gui.AGGIUNGIOPZIONESELECT('annullata', case p_stato when 'annullata' then true else false end, 'annullata');
    gui.CHIUDISELECTFORMFILTRO;

    gui.APRISELECTFORMFILTRO('p_tipo', 'tipo');
    gui.AGGIUNGIOPZIONESELECT(0, case p_tipo when 0 then true else false end, 'online');
    gui.AGGIUNGIOPZIONESELECT(1, case p_tipo when 1 then true else false end, 'telefoniche');
    gui.CHIUDISELECTFORMFILTRO;

    gui.AGGIUNGIRIGATABELLA();

    gui.APRISELECTFORMFILTRO('p_categoria', 'categoria');
    gui.AGGIUNGIOPZIONESELECT('standard', case p_categoria when 'standard' then true else false end, 'standard');
    gui.AGGIUNGIOPZIONESELECT('lusso', case p_categoria when 'lusso' then true else false end, 'lusso');
    gui.AGGIUNGIOPZIONESELECT('accessibili', case p_categoria when 'accessibili' then true else false end, 'accessibili');
    gui.CHIUDISELECTFORMFILTRO;
    if(ruolo='Operatore') then
        gui.AggiungiCampoFormFiltro('number', 'p_idCliente', p_idCliente, 'Cliente', minimo=>1);
        gui.AggiungiCampoFormFiltro('text', 'p_targa', p_targa, 'Targa taxi');
    end if;
    gui.AGGIUNGICAMPOFORMHIDDEN('text', 'p_idSess',p_idSess);
    gui.AggiungiCampoFormFiltro('submit', '', '', 'filtra');
    gui.chiudiFormFiltro();
    gui.ACAPO();

    --pulsante reset
    gui.ApriFormFiltro(u_root||'.visPren');
    gui.AggiungiCampoFormHidden('text', 'p_idSess', p_idSess);
    gui.AggiungiCampoFormFiltro('submit', '', '', 'Reset filtro');
    gui.ChiudiFormFiltro();
    GUI.ACAPO();

    gui.APRITABELLA(head);
        for x in (SELECT  IDPRENOTAZIONE, LUOGOPARTENZA, DATAORA, LUOGOARRIVO,NPERSONE, MODIFICATA, PRENOTAZIONI.STATO AS STATO, DURATA, TIPO,  FK_CLIENTE, NTELEFONO, PRENOTAZIONEACCESSIBILE.NPERSONEDISABILI,
            PRENOTAZIONESTANDARD.FK_PRENOTAZIONE AS idStandard, PRENOTAZIONELUSSO.FK_PRENOTAZIONE AS idLusso,
            PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE AS idAccessibile, ANONIMETELEFONICHE.FK_PRENOTAZIONE as idAnonimeTelefoniche,
            PRENOTAZIONEACCESSIBILE.FK_TAXIACCESSIBILE as idTaxiAccessibile, PRENOTAZIONESTANDARD.FK_TAXI as idTaxiStandard,
            PRENOTAZIONELUSSO.FK_TAXI as idTaxiLusso, TARGA
            FROM
                PRENOTAZIONI
            LEFT JOIN
                NONANONIME ON PRENOTAZIONI.IDPRENOTAZIONE = NONANONIME.FK_PRENOTAZIONE
            LEFT JOIN
                ANONIMETELEFONICHE ON PRENOTAZIONI.IDPRENOTAZIONE = ANONIMETELEFONICHE.FK_PRENOTAZIONE
            LEFT JOIN
                PRENOTAZIONESTANDARD ON  (p_categoria='standard' or p_categoria is null) AND PRENOTAZIONI.IDPRENOTAZIONE = PRENOTAZIONESTANDARD.FK_PRENOTAZIONE
            LEFT JOIN
                PRENOTAZIONELUSSO ON (p_categoria='lusso' or p_categoria is null) AND PRENOTAZIONI.IDPRENOTAZIONE = PRENOTAZIONELUSSO.FK_PRENOTAZIONE
            LEFT JOIN
                PRENOTAZIONEACCESSIBILE ON (p_categoria='accessibili' or p_categoria is null) AND PRENOTAZIONI.IDPRENOTAZIONE = PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE
            LEFT JOIN
                TAXI ON(PRENOTAZIONEACCESSIBILE.FK_TAXIACCESSIBILE=TAXI.IDTAXI OR PRENOTAZIONELUSSO.FK_TAXI=TAXI.IDTAXI OR PRENOTAZIONESTANDARD.FK_TAXI=TAXI.IDTAXI)
            where
                (ruolo='Operatore' or ruolo='Manager' or (ruolo='Cliente'and (NONANONIME.FK_CLIENTE=SESSIONHANDLER.GETIDUSER(p_idSess))))
                and
                (PRENOTAZIONI.IDPRENOTAZIONE = p_id or p_id is null)
                and (to_char(PRENOTAZIONI.DATAORA,'YYYY-MM-DD') between
                    case when p_data_min IS NULL then '0001-01-01' else p_data_min END AND
                    case when p_data_max  IS NULL then '9999-12-31' else p_data_max END)
                and (to_char(PRENOTAZIONI.DATAORA, 'HH24:MI') between
                    case when p_ora_min IS NULL then '00:00' else p_ora_min END AND
                    case when p_ora_max  IS NULL then '23:59' else p_ora_max END)
                and (LOWER(replace(PRENOTAZIONI.LUOGOPARTENZA, ' ', '')) = (LOWER(replace(p_partenza, ' ', ''))) or
                    p_partenza is null)
                    and (PRENOTAZIONI.Npersone = p_persone or p_persone is null)
                    and (LOWER(replace(PRENOTAZIONI.LUOGOARRIVO, ' ', '')) = (LOWER(replace(p_arrivo, ' ', ''))) or
                    p_arrivo is null)
                    and (PRENOTAZIONI.STATO = p_stato or p_stato is null)
                    and (PRENOTAZIONI.MODIFICATA = p_modificata or p_modificata is null)
                    and (PRENOTAZIONI.DURATA = p_durata or p_durata is null)
                    and (NONANONIME.TIPO=p_tipo or p_tipo is null)
                    and ((p_categoria='standard' and PRENOTAZIONESTANDARD.FK_PRENOTAZIONE is not null and PRENOTAZIONELUSSO.FK_PRENOTAZIONE is null  and PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE is null )
                        or (p_categoria='lusso' and PRENOTAZIONESTANDARD.FK_PRENOTAZIONE is null and PRENOTAZIONELUSSO.FK_PRENOTAZIONE is not null and PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE is null)
                        or (p_categoria='accessibili' and PRENOTAZIONESTANDARD.FK_PRENOTAZIONE is null and PRENOTAZIONELUSSO.FK_PRENOTAZIONE is null and PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE is not null)
                        or p_categoria is null)
                    and (LOWER(TARGA)=LOWER(p_targa) or p_targa is null)
                    and (FK_CLIENTE = p_idCliente OR p_idCliente is null)

            )loop
                gui.AggiungiRigaTabella();
                gui.AggiungiElementoTabella('' || x.IDprenotazione || '');
                gui.AggiungiElementoTabella(x.LuogoPartenza || '');
                gui.AggiungiElementoTabella(TO_CHAR(x.DataOra,'YYYY-MM-DD'));
                gui.AggiungiElementoTabella((to_char(x.DataOra, 'HH24:MI')));
                gui.AggiungiElementoTabella('' || x.LuogoArrivo || '');
                gui.AggiungiElementoTabella('' || x.Npersone || '');
                gui.AggiungiElementoTabella(case when x.Modificata=0 then 'no' ELSE 'si' END);
                gui.AggiungiElementoTabella('' || x.Stato || '');
                gui.AggiungiElementoTabella('' || x.Durata || '');
                gui.AggiungiElementoTabella(case when x.TIPO IS NOT NULL then
                    case when x.tipo=0 then  'online' ELSE 'telefonica' END
                        ELSE 'anonima telefonica ' END
                    );                                             --visualizza  tipo di prenotazione per operatore o manager
                if  x.idStandard is not null then
                    gui.AGGIUNGIELEMENTOTABELLA('standard');
                    else if x.idLusso is not null then             --elemento tabella dropdown optionals
                        optionals:= gui.StringArray();
                    For optional in (SELECT o.NOME FROM OPTIONALS o LEFT JOIN RICHIESTEPRENLUSSO rpl ON (rpl.FK_OPTIONALS= o.IDOPTIONALS) where rpl.FK_PRENOTAZIONE=x.IDPRENOTAZIONE)
                        loop
                            optionals.extend;
                            optionals(optionals.COUNT) := optional.NOME;
                        end loop;
                            UTILITY.DROPDOWNINFORMATION(optionals,'lusso');
                            else if x.idAccessibile is not null then
                                gui.AGGIUNGIELEMENTOTABELLA('accessibile posti disabili: '||x.NPERSONEDISABILI);
                            end if;
                        end if;
                    end if;
                    convenzioni:=gui.StringArray();
                    isCumulabile:=true;
                    For convenzione in (SELECT c.NOME, C.CUMULABILE FROM CONVENZIONI c JOIN CONVENZIONIAPPLICATE ca ON (c.IDCONVENZIONE=ca.FK_CONVENZIONE and ca.FK_NONANONIME=x.IDPRENOTAZIONE ))
                    loop
                        if convenzione.cumulabile=0 then
                            isCumulabile:=false;
                        end if;
                            convenzioni.extend;
                            Convenzioni(Convenzioni.COUNT) := convenzione.NOME;
                    end loop;
                    IF Convenzioni.COUNT=0 then gui.AGGIUNGIELEMENTOTABELLA('nessuna convenzione');
                    else if Convenzioni.COUNT>0 and isCumulabile=true then
                            utility.DROPDOWNINFORMATION(Convenzioni,'Cumulabili');
                            else
                            gui.AGGIUNGIELEMENTOTABELLA('non cumulabile: '||Convenzioni(1));

                        END IF;
                    END IF;
                    if ruolo='Operatore'or ruolo='Manager' then --informazioni su clienti e taxi

                        if x.idAnonimeTelefoniche is null then
                            gui.APRIELEMENTOPULSANTI();
                            gui.AGGIUNGIPULSANTEGENERALE(''''||U_USER||'.gruppo3.visualizzaProfilo?idSess='||p_idSess||'&id='||x.fk_cliente||'''','Utente:'||x.fk_cliente);
                            gui.CHIUDIELEMENTOPULSANTI();
                        else
                            gui.AGGIUNGIELEMENTOTABELLA('Anonimo: '||x.NTELEFONO);
                        end if;
                        if x.idTaxiStandard||x.idTaxiLusso||x.idTaxiAccessibile is null then
                            gui.AGGIUNGIELEMENTOTABELLA('nessun taxi associato');
                        else
                            gui.APRIELEMENTOPULSANTI();
                            gui.AGGIUNGIPULSANTEGENERALE(''''||U_USER||'.gruppo2.visualizzaUnTaxi?id_ses='||p_idSess||'&t_IDTaxi='||x.idTaxiStandard||x.idTaxiLusso||x.idTaxiAccessibile||'''','Taxi: '||x.targa);
                            gui.CHIUDIELEMENTOPULSANTI();
                        end if;
                    end if;
                    if ruolo<>'Manager' then
                        if(x.DATAORA > SYSDATE + INTERVAL '4' HOUR AND x.MODIFICATA = 0 AND (not x.STATO='rifiutata') ) THEN --pulsanti per modifica e annulla prenotazione
                            gui.APRIELEMENTOPULSANTI();
                                gui.AGGIUNGIPULSANTEMODIFICA(U_ROOT||'.ModificaPrenotazione?p_id_prenotazione='||x.IDPRENOTAZIONE||'&p_idSess='||p_idSess);
                                gui.AGGIUNGIPULSANTEGENERALE(''''||U_ROOT||'.annullaPren?p_idSess='||p_idSess||'&p_id_prenotazione='||x.IDPRENOTAZIONE||'''','annulla');
                            GUI.CHIUDIELEMENTOPULSANTI();
                        else
                            gui.AGGIUNGIELEMENTOTABELLA('non modificabile');
                        END if;
                    end if;
                    gui.ChiudiRigaTabella();
                end loop;

            gui.ChiudiTabella();
            gui.ACAPO();
            gui.CHIUDIPAGINA();
            EXCEPTION
                WHEN NoPermessi THEN
                    gui.APRIPAGINA('errore', null);
                    RETURN;
                when others then
                    gui.REINDIRIZZA(U_ROOT||'.visPren?p_idSess='||p_idSess);
                    RETURN;

    end visPren;
    PROCEDURE insPren(
        p_idSess in SESSIONICLIENTI.IDSESSIONE%TYPE DEFAULT NULL,
        p_idCliente in CLIENTI.IDCLIENTE%TYPE DEFAULT NULL,
        p_telefono in ANONIMETELEFONICHE.NTELEFONO%TYPE DEFAULT NULL,
        p_dataora in varchar2 default null,
        p_partenza in PRENOTAZIONI.LuogoPartenza%TYPE default null,
        p_persone in PRENOTAZIONI.Npersone%TYPE default null,
        p_arrivo in PRENOTAZIONI.LuogoArrivo%TYPE default null,
        p_durata in PRENOTAZIONI.DURATA%TYPE default null,
        p_convenzioniCumulabili in varchar2 default null,
        p_convenzione in CONVENZIONI.IDCONVENZIONE%TYPE DEFAULT NULL,
        p_optionals in varchar2 default null,
        p_disabili in PRENOTAZIONEACCESSIBILE.NPERSONEDISABILI%TYPE default null,
        p_stato in PRENOTAZIONI.STATO%TYPE default 'pendente',
        p_id_taxi in TAXI.IDTAXI%TYPE default null,
        p_visPrenBoolean in integer default null,
        p_insConvBoolean in integer default 0)
    is
        optionals gui.StringArray := gui.StringArray();
        optionalsId gui.StringArray := gui.StringArray();
        convenzioni gui.STRINGARRAY := gui.STRINGARRAY();
        convenzioniId gui.STRINGARRAY := gui.STRINGARRAY();
        idCliente int;
        v_idPrenotazione int;
        ruolo varchar2(10);
        durata int;
begin
    --Controllo permessi
    ruolo:=SESSIONHANDLER.GETRUOLO(p_idSess);
    if ruolo='Cliente' then
        idCliente:=SESSIONHANDLER.GETIDUSER(p_idSess);
    else if ruolo='Operatore' then
        idCliente:=p_idCliente;
        else
            raise NOPERMESSI;
        end if;
    end if;
    if p_dataora is null or p_partenza is null or p_persone is null or p_arrivo is null or p_insConvBoolean=1 then
        --INSERIMENTO DATI PRENOTAZION
        gui.APRIPAGINA('Inserisci prenotazione',p_idSess,'
            function showFieldsInsPrenCategoria() {
            const disabili = document.getElementById("p_disabili");
            var optionalsin = document.getElementById("p_optionalsh");
            const disabiliin = document.getElementById("p_disabilih");
            const optionals = document.getElementById("p_optionals_show");
            const standard = document.getElementsByName("categoria")[0];
            const lusso = document.getElementsByName("categoria")[1];
            const accessibile = document.getElementsByName("categoria")[2];//console.log(optionalsin.value);
            if (accessibile.checked) {
                disabili.classList.remove("hidden");
                optionals.classList.add("hidden");
                optionalsin.value="";
            } if(standard.checked) {
                optionals.classList.add("hidden");
                disabili.classList.add("hidden");
                optionalsin.value="";
                disabiliin.value="";
            }
            if(lusso.checked) {
                disabili.classList.add("hidden");
                optionals.classList.remove("hidden");
                disabiliin.value="";
            }
        }
        function showFieldsInsPrenTipo() {
            const cliente = document.getElementById("p_idCliente");
            const telefono = document.getElementById("p_telefono");
            const clientein = document.getElementById("p_idClienteH");
            const telefonoin = document.getElementById("p_telefonoH");
            const anonime = document.getElementsByName("tipo")[0];
            const nonanonime = document.getElementsByName("tipo")[1];
            if (anonime.checked) {
                telefono.classList.remove("hidden");
                cliente.classList.add("hidden");
                telefonoin.value="";
            } if(nonanonime.checked) {
                telefono.classList.add("hidden");
                cliente.classList.remove("hidden");
                clientein.value="";
            }
        }
         function sendCorrectData(){
            event.preventDefault();const standard = document.getElementsByName("categoria")[0];
            const lusso = document.getElementsByName("categoria")[1];
            const accessibile = document.getElementsByName("categoria")[2];
            var optionalsin = document.getElementById("p_optionals");
            var disabiliin = document.getElementById("p_disabilih");
                console.log(optionalsin.value);
             if(lusso.checked &&  optionalsin.value==="") {
                optionalsin.value="-1";
            }
            if(!lusso.checked) {
                    optionalsin.value="";
            }
            if(!accessibile.checked) {
                    disabiliin.value="";
            }document.getElementsByName("form")[0].submit();
        }
        ');
        gui.AGGIUNGIINTESTAZIONE('Inserisci prenotazione', 'h1');

        gui.ACAPO();

        if p_visPrenBoolean is not null  then
            case p_visPrenBoolean
                when 0 then
                    gui.AGGIUNGIPOPUP(false,'inserimento fallito: non puoi selezionare convenzioni cumulabili e non cumulabili');
                when 1 then
                    gui.AGGIUNGIPOPUP(false,'inserimento fallito: non puoi selezionare optionals e posti disabili');
                when 2 then
                    gui.AGGIUNGIPOPUP(false,'inserimento fallito: dati non corretti');
                when 3 then
                    gui.AGGIUNGIPOPUP(false,'inserimento fallito: in un prenotazione accessibile non possono esserci più di 3 posti ordinari');
                when 4 then
                    gui.AggiungiPopup(false, 'Errore nell'||chr(39)||'inserimento dei parametri.');
                when 5 then
                    gui.AggiungiPopup(false, 'Impossibile inserire prenotazioni passate.');
                end case;
            gui.ACAPO();
        end if;

        --form scelta categorie
        if(p_insConvBoolean=0) then
            gui.AGGIUNGIFORM();
            gui.apriDiv(classe => 'row', onClick=>'showFieldsInsPrenCategoria()');
            gui.AGGIUNGIGRUPPOINPUT();
                gui.AGGIUNGIINPUT (nome =>'categoria', ident => 'standard', tipo => 'radio', selected =>true);
                gui.AGGIUNGILABEL (target =>'standard', testo =>'standard');
                gui.AGGIUNGIINPUT (nome =>'categoria', ident => 'lusso', tipo => 'radio');
                gui.AGGIUNGILABEL (target =>'lusso', testo => 'lusso');
                gui.AGGIUNGIINPUT (nome =>'categoria', ident => 'accessibile', tipo => 'radio');
                gui.AGGIUNGILABEL (target =>'accessibile', testo => 'accessibile');
            gui.CHIUDIGRUPPOINPUT();
            if(ruolo='Operatore') then
            gui.apriDiv(classe => 'row', onClick=>'showFieldsInsPrenTipo()');
                GUI.AGGIUNGIGRUPPOINPUT();
                    gui.AGGIUNGIINPUT (nome =>'tipo', ident => 'anonime', tipo => 'radio', selected =>true);
                    gui.AGGIUNGILABEL (target =>'anonime', testo =>'anonime');
                    gui.AGGIUNGIINPUT (nome =>'tipo', ident => 'nonanonime', tipo => 'radio');
                    gui.AGGIUNGILABEL (target =>'nonanonime', testo => 'non anonime');
                GUI.CHIUDIGRUPPOINPUT();
            gui.CHIUDIDIV();
            end if;
            gui.CHIUDIDIV();
            gui.CHIUDIFORM();
        end if;
        gui.ACAPO();

        --form inserimento dati
        if(ruolo='Cliente') then
            gui.AGGIUNGIFORM(url=>u_root||'.insPren', onSubmit=>'sendCorrectData()', name=>'form');
        end if;
        if(ruolo='Operatore'  and p_insConvBoolean=0) then
            gui.AGGIUNGIFORM(url=>u_root||'.taxiCheSodd', onSubmit=>'sendCorrectData()', name=>'form');
        end if;
        if(ruolo='Operatore' and p_insConvBoolean=1) then
            gui.AGGIUNGIFORM(url=>u_root||'.insPren');
        end if;
        if(ruolo='Operatore') then
            if p_insConvBoolean=0 then
            gui.AGGIUNGIINTESTAZIONE('dati cliente', 'h2');
            gui.AGGIUNGIGRUPPOINPUT();
                GUI.APRIDIV(ident=>'p_idCliente', classe=>'hidden');
                    gui.AGGIUNGICAMPOFORM(tipo=> 'number', nome=>'p_idCliente', value=>p_idCliente, placeholder=>'id Cliente',CLASSEICONA=>'fa fa-id-card',ident=>'p_idClienteH',required=>false);
                GUI.CHIUDIDIV();
            gui.CHIUDIGRUPPOINPUT();
            gui.AGGIUNGIGRUPPOINPUT();
                GUI.APRIDIV(ident=>'p_telefono');
                    gui.AGGIUNGICAMPOFORM(TIPO => 'number', NOME=>'p_telefono', VALUE=>p_telefono, PLACEHOLDER => 'telefono', CLASSEICONA=>'fa fa-phone',ident=>'p_telefonoH',required=>false);
                GUI.CHIUDIDIV();
            gui.CHIUDIGRUPPOINPUT();
            else
                gui.AGGIUNGICAMPOFORMHIDDEN('number', 'p_idCliente',p_idCliente);
                gui.AGGIUNGICAMPOFORMHIDDEN('number', 'p_telefono',p_telefono);
            end if;
        end if;
        if p_insConvBoolean=0 then
            gui.AGGIUNGIINTESTAZIONE('Data di partenza', 'h2');
            gui.AGGIUNGICAMPOFORM(tipo=>'datetime-local', nome=>'p_dataora', value=>p_dataora, placeHolder=>'Data',required=>true, minimo=>to_char(sysdate,'YYYY-MM-DD HH24:MI'),CLASSEICONA=>'fa fa-calendar', massimo=>to_char(sysdate+7,'YYYY-MM-DD HH24:MI'));
            gui.AGGIUNGIINTESTAZIONE('Info', 'h2');
            gui.AGGIUNGIGRUPPOINPUT();
                gui.AGGIUNGICAMPOFORM(tipo=>'text', nome=>'p_partenza', value=>p_partenza, placeholder=>'Luogo di Partenza',required=>true, classeicona=>'fa fa-play');
                gui.AGGIUNGICAMPOFORM(tipo=>'text', nome=>'p_arrivo', value=>p_arrivo, placeholder=>'Luogo di Arrivo',required=>true, classeicona=>'fa fa-stop');
                gui.AGGIUNGICAMPOFORM(tipo=>'number', nome=>'p_persone', value=>p_persone, placeholder=>'Persone',required=>true, minimo=>1, massimo=>8, classeicona=>'fa fa-users');
            gui.CHIUDIGRUPPOINPUT();
            else
                gui.AGGIUNGICAMPOFORMHIDDEN('datetime-local', 'p_dataora',p_dataora);
                gui.AGGIUNGICAMPOFORMHIDDEN('text', 'p_partenza',p_partenza);
                gui.AGGIUNGICAMPOFORMHIDDEN('text', 'p_arrivo',p_arrivo);
                gui.AGGIUNGICAMPOFORMHIDDEN('number', 'p_persone',p_persone);

        end if;
        if ruolo='Cliente' or (ruolo='Operatore'and idCliente is not null and p_insConvBoolean=1) then
            gui.AGGIUNGIGRUPPOINPUT();
                gui.AGGIUNGICAMPOFORMHIDDEN('text', 'p_convenzioniCumulabili');
                convenzioni:= gui.STRINGARRAY();--Dropdown dinamico per le convenzioni cumulabili
                convenzioniId:= gui.STRINGARRAY();
                For convenzione in (SELECT c.NOME, c.IDCONVENZIONE FROM CONVENZIONI c join CONVENZIONICLIENTI cc ON(cc.FK_CLIENTE=idCliente)
                    where c.IDCONVENZIONE=cc.FK_CONVENZIONE
                    and c.CUMULABILE=1
                    and c.DATAFINE>SYSDATE
                )
                    loop
                        convenzioni.extend;
                        convenzioni(convenzioni.COUNT) := convenzione.nome;
                        convenzioniId.extend;
                        convenzioniId(convenzioniID.COUNT) := convenzione.IDCONVENZIONE;
                    end loop;
                if(convenzioni.count>0) then
                    gui.AGGIUNGISELEZIONEMULTIPLA('convenzioni cumulabili', 'convenzioni cumulabili', convenzioniId,convenzioni, 'p_convenzioniCumulabili',ident=>'cumulabile');
                END IF;
                convenzioni:= gui.STRINGARRAY();--menu select per convenzioni non cumulabili
                convenzioniId:= gui.STRINGARRAY();
                For convenzione in (SELECT c.NOME, c.IDCONVENZIONE FROM CONVENZIONI c join CONVENZIONICLIENTI cc ON(cc.FK_CLIENTE=idCliente)
                    where c.IDCONVENZIONE=cc.FK_CONVENZIONE
                    and c.CUMULABILE=0
                    and  c.DATAFINE>SYSDATE)
                    loop
                        convenzioni.extend;
                        convenzioni(convenzioni.COUNT) := convenzione.nome;
                        convenzioniId.extend;
                        convenzioniId(convenzioniID.COUNT) := convenzione.IDCONVENZIONE;
                    end loop;
                if(convenzioni.count>0) then
                    gui.AGGIUNGISELEZIONESINGOLA(convenzioni,convenzioniId,'convenzioni non cumulabili','p_convenzione' );
                end if;
            gui.CHIUDIGRUPPOINPUT();
            gui.AGGIUNGICAMPOFORMHIDDEN('number', 'p_insConvBoolean',0);
        end if;
        gui.AGGIUNGIGRUPPOINPUT();
            GUI.APRIDIV(ident=>'p_disabili', classe=>'hidden');
            GUI.AGGIUNGICAMPOFORM(tipo=>'number', nome=>'p_disabili', value=>p_disabili, placeholder=>'Disabili',minimo=>1, massimo=>2, classeIcona=>'fa fa-wheelchair', ident=>'p_disabilih',required=>false);
            gui.CHIUDIDIV();

            GUI.AGGIUNGICAMPOFORMHIDDEN('text', 'p_optionals', p_optionals, ident=>'p_optionals');
            optionals:= gui.StringArray();--dropdown dinamico per gli optionals
            For optional in (SELECT DISTINCT o.NOME, o.IDOPTIONALS FROM OPTIONALS o JOIN POSSIEDETAXILUSSO ptl on o.IDOPTIONALS=ptl.FK_OPTIONALS)
                loop
                   optionals.extend;
                   optionals(optionals.COUNT) := optional.NOME;
                   optionalsId.extend;
                   optionalsId(optionalsID.COUNT) := optional.IDOPTIONALS;

                end loop;
                gui.APRIDIV(ident=>'p_optionals_show', classe=>'hidden');
                gui.AGGIUNGISELEZIONEMULTIPLA('optionals', 'Optionals', optionalsId,optionals, 'p_optionals',ident=>'optionals');
                gui.CHIUDIDIV();
        gui.CHIUDIGRUPPOINPUT();
        gui.AGGIUNGICAMPOFORMHIDDEN('text', 'p_idSess',p_idSess);
        if (p_insConvBoolean=1) then
            gui.AGGIUNGICAMPOFORMHIDDEN('number', 'p_durata',p_durata);
            gui.AGGIUNGICAMPOFORMHIDDEN('text', 'p_stato',p_stato);
            gui.AGGIUNGICAMPOFORMHIDDEN('number', 'p_id_taxi',p_id_taxi);
        end if;
        gui.AGGIUNGIGRUPPOINPUT();
        if(p_insConvBoolean=0 and ruolo='Operatore') then
            gui.AGGIUNGIBOTTONESUBMIT('taxi liberi');
        else
            gui.AGGIUNGIBOTTONESUBMIT('Prenota');
            end if;
        gui.CHIUDIGRUPPOINPUT();
        gui.CHIUDIFORM();
        gui.ACAPO();
        gui.CHIUDIPAGINA();
        else--REGISTRAZIONE PRENOTAZIONE
            savepoint startInsert;
            if(ruolo='Cliente') then durata:=FLOOR(DBMS_RANDOM.VALUE(10, 30)); end if;
            if(ruolo='Operatore') then durata:=p_durata; end if;
            --insert comuni ad ogni prenotazione
            v_idPrenotazione:=seq_idPrenotazione.nextval;
            INSERT INTO PRENOTAZIONI VALUES(v_idPrenotazione,to_date(p_dataora,'YYYY-MM-DD"T"HH24:MI'),p_partenza, p_persone, p_arrivo, p_stato, 0, durata);

            if(ruolo='Cliente' or (ruolo='Operatore' and p_idCliente is not null))then
                 INSERT INTO NONANONIME VALUES(v_idPrenotazione,NULL,idCliente,0);
            end if;
            if(ruolo='Operatore' and p_telefono is not null)then
                INSERT INTO ANONIMETELEFONICHE VALUES(v_idPrenotazione,SESSIONHANDLER.GETIDUSER(p_idSess),p_telefono);
            end if;
            if p_convenzioniCumulabili is not null and p_convenzione is not null then
                ROLLBACK TO SAVEPOINT startInsert;
                gui.REINDIRIZZA(u_root||'.InsPren?p_idsess='||p_idSess||'&p_visPrenBoolean=0');
                RETURN;
                else
                if p_convenzioniCumulabili is not null and p_convenzione is null then--utente ha selezionato tutti e due i tipi di convenzioni
                    convenzioniId:=gui.StringArray();
                    convenzioniId:=UTILITY.STRINGTOARRAY(p_convenzioniCumulabili);
                    for i in 1.. convenzioniId.count loop
                        insert into CONVENZIONIAPPLICATE values(convenzioniId(i),v_idPrenotazione);
                    end loop;
                    else
                        if p_convenzione is not null and p_convenzioniCumulabili is null then
                        insert into CONVENZIONIAPPLICATE values(p_convenzione,v_idPrenotazione);
                    end if;
                end if;
            end if;
            --insert specifiche per categoria prenotazione
            if p_optionals is not null and p_disabili is null then--prenotazione di lusso
                insert into PRENOTAZIONELUSSO(FK_PRENOTAZIONE) values(v_idPrenotazione);
                if(Ruolo='Operatore' and p_id_taxi is not null) then
                    update PRENOTAZIONELUSSO SET FK_TAXI=p_id_taxi WHERE FK_PRENOTAZIONE=v_idPrenotazione;
                end if;
                optionalsId:=gui.StringArray();
                optionalsId:=UTILITY.STRINGTOARRAY(p_optionals);
                if(optionalsId(1)<>'-1') then
                    for i in 1.. optionalsId.count loop
                        insert into RICHIESTEPRENLUSSO values(v_idPrenotazione, optionalsId(i));
                    end loop;
                end if;
                gui.REINDIRIZZA(u_root||'.visPren?p_idSess='||p_idSess||'&p_id='||v_idPrenotazione||'&p_visPrenBoolean=1');
                RETURN;
            else if  p_disabili is not null and p_optionals is null then --prenotazione accessibile
                if p_persone>3 then --In una prenotazione per disabili non ci possono essere più di 3 posti normali
                    rollback to startInsert;
                    gui.REINDIRIZZA(u_root||'.InsPren?p_idsess='||p_idSess||'&p_visPrenBoolean=3');
                    return;
                end if;
                insert into PRENOTAZIONEACCESSIBILE values(v_idPrenotazione,null,p_disabili);
                if(Ruolo='Operatore' and p_id_taxi is not null) then
                    update PRENOTAZIONEACCESSIBILE SET FK_TAXIACCESSIBILE=p_id_taxi WHERE FK_PRENOTAZIONE=v_idPrenotazione;
                end if;
                gui.REINDIRIZZA(u_root||'.visPren?p_idSess='||p_idSess||'&p_id='||v_idPrenotazione||'&p_visPrenBoolean=2');
                RETURN;
                else if p_disabili is null  and p_optionals is null then
                    insert into PRENOTAZIONESTANDARD VALUES(v_idPrenotazione,null);
                    if(Ruolo='Operatore' and p_id_taxi is not null) then
                        update PRENOTAZIONESTANDARD SET FK_TAXI=p_id_taxi WHERE FK_PRENOTAZIONE=v_idPrenotazione;
                    end if;
                    gui.REINDIRIZZA(u_root||'.visPren?p_idSess='||p_idSess||'&p_id='||v_idPrenotazione||'&p_visPrenBoolean=0');
                    RETURN;
                    else
                      ROLLBACK TO startInsert;
                      gui.REINDIRIZZA(u_root||'.InsPren?p_idsess='||p_idSess||'&p_visPrenBoolean=1');
                      RETURN;
                end if;
            end if;
            end if;
        COMMIT;
        end if;
        return;
        EXCEPTION
            WHEN NoPermessi THEN
                gui.APRIPAGINA('errore',null);
                return;
            WHEN OTHERS THEN
                ROLLBACK to  startInsert;
                gui.REINDIRIZZA(u_root||'.InsPren?p_idsess='||p_idSess||'&p_visPrenBoolean=2');
                RETURN;
    end insPren;
    PROCEDURE loadStats(
        p_idSess in SESSIONICLIENTI.IDSESSIONE%TYPE DEFAULT NULL,
        p_dataOraI in VARCHAR2 default null,
        p_dataOraF in VARCHAR2 default null,
        p_interval in integer default null
    )is
        starti date;
        stopi date;
        stopwhile date;
          TYPE FloatArray IS TABLE OF varchar2(10) INDEX BY PLS_INTEGER;
        r FloatArray;
        c int;
        labels varchar2(5000);
        pStandard varchar2(5000);
        pLusso varchar2(5000);
        pAccessibile varchar2(5000);
        tStandard varchar2(5000);
        tLusso varchar2(5000);
        tAccessibile varchar2(5000);
    begin
        if(not SESSIONHANDLER.CHECKRUOLO(p_idSess, 'Manager')) then
            raise NOPERMESSI;
        end if;
        if p_dataOraI is null or p_dataOraF is null or p_interval is null then
               gui.APRIPAGINA('Saturazione del servizio', p_idSess);
               gui.AGGIUNGIFORM(url=>U_ROOT||'.loadStats');
                gui.AGGIUNGIGRUPPOINPUT();
                    gui.AGGIUNGIINTESTAZIONE('inizio','h3');
                    gui.AGGIUNGICAMPOFORM(tipo=>'datetime-local', nome=>'p_DataOraI', value=>p_dataOraI, placeHolder=>'Data di inizio',required=> true,CLASSEICONA=>'fa fa-calendar');
                    gui.AGGIUNGIINTESTAZIONE('fine','h3');
                    gui.AGGIUNGICAMPOFORM(tipo=>'datetime-local', nome=>'p_DataOraF', value=>p_dataOraF, placeHolder=>'Data di fine',required=> true,CLASSEICONA=>'fa fa-calendar');
                    gui.AGGIUNGIINTESTAZIONE('minuti intervallo','h3');
                    gui.AGGIUNGICAMPOFORM(tipo=>'number', nome=>'p_interval', value=>p_interval, placeHolder=>'intervallo',required=> true,CLASSEICONA=>'fa fa-calendar');
               gui.CHIUDIGRUPPOINPUT();
               gui.AGGIUNGICAMPOFORMHIDDEN('text', 'p_idSess',p_idSess);
               gui.AGGIUNGIGRUPPOINPUT();
                    gui.AGGIUNGIBOTTONESUBMIT('Calcola');
                gui.CHIUDIGRUPPOINPUT();
               gui.CHIUDIFORM();
        else
            gui.APRIPAGINA('Saturazione del servizio', p_idSess);
            starti:=TO_DATE(p_dataOraI, 'YYYY-MM-DD"T"HH24:MI');
            stopwhile:=TO_DATE(p_dataOraF, 'YYYY-MM-DD"T"HH24:MI');
            gui.AGGIUNGIINTESTAZIONE('Stato del servizio','h1');
            gui.AGGIUNGIINTESTAZIONE('inizio:'||TO_CHAR(starti,'YYYY-MM-DD HH24:MI')||' fine:'||TO_CHAR(stopwhile,'YYYY-MM-DD HH24:MI')|| ' Intervallo:'||to_char(p_interval)||case p_interval when 1 then ' minuto' else ' minuti' end,'h3');
            gui.acapo();
            gui.BOTTONEAGGIUNGI(url=>U_ROOT||'.loadStats?p_idSess='||p_idSess,testo=>'reinserisci range');
            gui.APRITABELLA(gui.STRINGARRAY('ora','numero corse standard','taxi standard occupati','numero corse accessibili','taxi standard accessibili','numero corse lusso','taxi lusso occupati'));

            stopi:=starti+ (p_interval / (24 * 60));
                WHILE STARTI< stopwhile LOOP
                    gui.AGGIUNGIRIGATABELLA();
                    gui.AGGIUNGIELEMENTOTABELLA(TO_CHAR(STARTI,'YYYY-MM-DD HH24:MI') || '<->'|| TO_CHAR(STOPI,'YYYY-MM-DD HH24:MI'));
                    for i in 1..6 loop
                           r(i):='0';
                        end loop;
                    SELECT COUNT(*) into c FROM STATISTICHEAFFLUSSO WHERE STATISTICHEAFFLUSSO.ORA BETWEEN STARTI AND STOPI;
                    IF(c)>0 THEN
                        SELECT TO_CHAR(SUM(NCORSESTANDARD)) AS nCorseStandard,
                        TO_CHAR(ROUND(SUM(NCORSESTANDARD) / (SELECT COUNT(*) FROM TAXISTANDARD JOIN Taxi ON TAXISTANDARD.FK_TAXI = Taxi.IDTAXI) * 100, 2)) AS TaxiStandardOccupati,
                        TO_CHAR(SUM(NCORSEACCESSIBILI)) AS nCorseAccessibili,
                        TO_CHAR(ROUND(SUM(NCORSEACCESSIBILI) / (SELECT COUNT(*) FROM TAXIACCESSIBILE JOIN Taxi ON TAXIACCESSIBILE.FK_TAXI = Taxi.IDTAXI) * 100, 2)) AS TaxiAccessibiliOccupati,
                        TO_CHAR(SUM(NCORSELUSSO)) AS nCorseLusso,
                        TO_CHAR(ROUND(SUM(NCORSELUSSO) / (SELECT COUNT(*) FROM TAXILUSSO JOIN Taxi ON TAXILUSSO.FK_TAXI = Taxi.IDTAXI) * 100, 2)) AS TaxiLussoOccupati
                                into  r(1),r(2),r(3),r(4),r(5),r(6)
                        FROM STATISTICHEAFFLUSSO
                        where
                            STATISTICHEAFFLUSSO.ORA BETWEEN starti AND stopi
                        group by id;

                        labels:=labels||','||chr(39)||TO_CHAR(STARTI,'YYYY-MM-DD HH24:MI') || '<->'|| TO_CHAR(STOPI,'YYYY-MM-DD HH24:MI')||chr(39);
                        pStandard:=Pstandard||','|| '' || R(1) || '';
                        tStandard:=tstandard||','|| '' || R(2) || '';
                        pAccessibile:=pAccessibile||','|| '' || R(3) || '';
                        tAccessibile:=tAccessibile||','|| '' || R(4) || '';
                        pLusso:=pLusso||','|| '' || R(5) || '';
                        tLusso:=tLusso||','|| '' || R(6) || '';
                    end if;
                for i in 1..r.COUNT loop
                   if MOD(i, 2) = 0 then
                   gui.AGGIUNGIELEMENTOTABELLA( r(i)||'%');
                   else
                        gui.AGGIUNGIELEMENTOTABELLA( r(i));
                   end if;
                end loop;

            STARTI:=STOPI;
            STOPI:=starti+ (p_interval / (24 * 60));
            END LOOP;
            gui.CHIUDITABELLA();
            gui.aCapo(2);

            gui.aggiungiChart('stats', '{
                                    type: '||chr(39)||'bar'||chr(39)||',
                                    data: {
                                    labels: ['||labels||'],
                                    datasets: [{
                                        label: '||chr(39)||'corse standard'||chr(39)||',
                                        data: ['||pStandard||'],
                                        borderWidth: 1
                                    },{
                                        label: '||chr(39)||'taxi standard occupati'||chr(39)||',
                                        data: ['||tStandard||'],
                                        borderWidth: 1
                                    },
                                    {
                                        label: '||chr(39)||'corse lusso'||chr(39)||',
                                        data: ['||pLusso||'],
                                        borderWidth: 1
                                    },
                                    {
                                      label: '||chr(39)||'taxi lusso occupati'||chr(39)||',
                                      data: ['||tLusso||'],
                                      borderWidth: 1
                                    },
                                    {
                                        label: '||chr(39)||' corse accessibili'||chr(39)||',
                                        data: ['||pAccessibile||'],
                                        borderWidth: 1
                                    },
                                    {
                                      label: '||chr(39)||'taxi accessibili occupati'||chr(39)||',
                                      data: ['||tAccessibile||'],
                                      borderWidth: 1
                                    }]
                                    },
                                    options: {
                                    scales: {
                                        y: {
                                        beginAtZero: true
                                        }
                                    }
                                    }
                                }');
            gui.aCapo(2);
        end if;
        gui.CHIUDIPAGINA();
        EXCEPTION
            WHEN NOPERMESSI THEN
                gui.APRIPAGINA('errore',null);
                RETURN;
            when others then
                gui.REINDIRIZZA(u_root||'.loadstats?p_idSess='||p_idSess);
                return;
    end loadStats;
--------------------------------Ceccotti--------------------------------------
    procedure visualizzaPrenotazioniPendenti(
        p_idSess            in SESSIONIDIPENDENTI.IDSESSIONE%TYPE default '-1',
        p_id                in PRENOTAZIONI.IDPRENOTAZIONE%TYPE default null,
        p_data1             in varchar2 default null,
        p_data2             in varchar2 default null,
        p_partenza          in PRENOTAZIONI.LUOGOPARTENZA%TYPE default null,
        p_persone           in PRENOTAZIONI.NPERSONE%TYPE default null,
        p_arrivo            in PRENOTAZIONI.LUOGOARRIVO%TYPE default null,
        p_durata            in PRENOTAZIONI.DURATA%TYPE default null,
        p_filterSubmit      in varchar2 default null,
        p_ordina            in varchar2 default null,
        p_ascdesc           in varchar2 default null,
        p_accetta_id        in PRENOTAZIONI.IDPRENOTAZIONE%TYPE default null,
        p_accetta           in VARCHAR2 default null,
        p_offset            in int default 0
    ) is
        head gui.stringArray;
        id_taxi             TURNI.FK_TAXI%TYPE;
        turno               TURNI%ROWTYPE;
        v_postiTaxiAccess   TAXIACCESSIBILE.NPERSONEDISABILI%TYPE := 0;
        postiTaxi           TAXI.NPOSTI%TYPE;
        tipoTaxi            VARCHAR(1);
        fk_taxiStandard     TAXISTANDARD.FK_TAXI%TYPE := 0;
        v_stato             TAXI.STATO%TYPE;
        currentDate         date;
        dataOraArrivo       date;
        arrayOptionals      gui.StringArray;
    begin

        if (p_filterSubmit = 'R') THEN
            gui.reindirizza(u_root || '.visualizzaPrenotazioniPendenti?p_idSess='||p_idSess);
        end if;

        --Controlla che si stia cercando di accedere alla procedura con i giusti permessi
        if not SessionHandler.checkruolo(p_idSess, 'Autista') then
            gui.aggiungiPopup(false, 'Non hai i permessi per visualizzare questa pagina');
            RETURN;
        end if;

        gui.ApriPagina('Prenotazioni Pendenti', p_idSess);

        gui.acapo;
        gui.AggiungiIntestazione('Visualizza prenotazioni pendenti', 'h1');

        gui.aCapo;

        -- Popup per il riscontro di potenziali errori durante l'accettazione di una prenotazione
        if p_accetta = 'F' then
            gui.aggiungiPopup(false, 'Si è verificato un errore durante l'||CHR(39)||'accettazione, la prenotazione è gia stata accettata');
        end if;

        gui.aCapo;

        currentDate := SYSDATE;

        -- Prende il turno corrente
        SELECT * into turno From TURNI WHERE TURNI.FK_AUTISTA = SessionHandler.GETIDUSER(p_idSess)
                        and Turni.DATAORAINIZIO <= currentDate
                        and Turni.DATAORAFINE >= currentDate;

        -- Informazioni riguardo il tipo del taxi, posti e stato
        SELECT TAXI.NPOSTI, TAXI.STATO, TAXIACCESSIBILE.NPERSONEDISABILI, TAXISTANDARD.FK_TAXI into postiTaxi, v_stato, v_postiTaxiAccess, fk_taxiStandard
        FROM TAXI
        LEFT JOIN TAXIACCESSIBILE ON TAXIACCESSIBILE.FK_TAXI = IDTAXI
        LEFT JOIN TAXILUSSO ON TAXILUSSO.FK_TAXI = IDTAXI
        LEFT JOIN TAXISTANDARD ON TAXISTANDARD.FK_TAXI = IDTAXI
        WHERE (TAXI.IDTAXI = turno.FK_TAXI);

        -- Controllo del tipo
        if(v_postiTaxiAccess is not null) then
            tipoTaxi := 'A';
        elsif (fk_taxiStandard is not null) then
            tipoTaxi := 'S';
        else
            tipoTaxi := 'L';
        end if;

        -- Filtro
        gui.ApriFormFiltro(u_root||'.visualizzaPrenotazioniPendenti');
            gui.AggiungiRigaTabella();

                gui.AggiungiCampoFormFiltro('number', 'p_id', p_id, 'ID', minimo => '0');
                gui.AggiungiCampoFormFiltro('text', 'p_partenza', p_partenza, 'Luogo di Partenza');
                gui.AggiungiCampoFormFiltro('text', 'p_arrivo', p_arrivo, 'Luogo di Arrivo');
                gui.AggiungiCampoFormFiltro('time', 'p_data1', p_data1, 'Ora di Partenza (Da)', minimo => to_char(turno.DATAORAINIZIO, 'HH24:MM'), massimo => to_char(turno.DATAORAFINE, 'HH24:MI'));
                gui.AggiungiCampoFormFiltro('time', 'p_data2', p_data2, 'Ora di Partenza (A)', minimo => to_char(turno.DATAORAINIZIO, 'HH24:MI'), massimo => to_char(turno.DATAORAFINE, 'HH24:MI'));

                gui.AggiungiCampoFormFiltro('submit', 'p_filterSubmit', 'F', 'Filtra');

            gui.chiudiRigaTabella();

            gui.AggiungiRigaTabella();

                gui.AggiungiCampoFormFiltro('number', 'p_persone', p_persone, 'Persone', minimo => '0');
                gui.AggiungiCampoFormFiltro('number', 'p_durata', p_durata, 'Durata', minimo => '0');
                gui.AGGIUNGIELEMENTOTABELLA('');

                gui.ApriSelectFormFiltro('p_ordina', 'Campo da ordinare');
                    gui.AggiungiOpzioneSelect('IDPRENOTAZIONE', p_ordina = 'IDPRENOTAZIONE', 'ID');
                    gui.AggiungiOpzioneSelect('ORA', p_ordina = 'ORA', 'Ora');
                    gui.AggiungiOpzioneSelect('DURATA', p_ordina = 'DURATA', 'Durata');
                    gui.AggiungiOpzioneSelect('PARTENZA', p_ordina = 'PARTENZA', 'Luogo di partenza');
                    gui.AggiungiOpzioneSelect('ARRIVO', p_ordina = 'ARRIVO', 'Luogo di arrivo');
                    gui.AggiungiOpzioneSelect('NPERSONE', p_ordina = 'NPERSONE', 'Persone');
                gui.ChiudiSelectFormFiltro();

                gui.ApriSelectFormFiltro('p_ascdesc', 'Ordinamento');
                    gui.AggiungiOpzioneSelect('asc', p_ascdesc = 'asc', 'Crescente');
                    gui.AggiungiOpzioneSelect('desc', p_ascdesc = 'desc', 'Decrescente');
                gui.ChiudiSelectFormFiltro();

                gui.AggiungiCampoFormFiltro('submit', 'p_filterSubmit', 'R', 'Reset');

        gui.chiudiRigaTabella();

        -- Campo hidden, ID_sessione
        gui.AggiungiCampoFormHidden('number', 'p_idSess', p_idSess);


        gui.chiudiFormFiltro();

        htp.prn('<br>');

        -- Imposta differenti headers a seconda del tipo del taxi
        if tipoTaxi = 'A' then
            head := gui.StringArray('ID', 'Luogo di Partenza', 'Ora di Partenza', 'Luogo di Arrivo',
                                'Persone','Durata', 'Posti per disabili', ' ');
        else
            head := gui.StringArray('ID', 'Luogo di Partenza',  'Ora di Partenza', 'Luogo di Arrivo',
                                'Persone','Durata', ' ');
        end if;

        gui.ApriTabella(head);

        for x in (SELECT PRENOTAZIONI.*, PRENOTAZIONEACCESSIBILE.NPERSONEDISABILI
                FROM PRENOTAZIONI
                LEFT JOIN PRENOTAZIONESTANDARD ON (tipoTaxi='S') AND PRENOTAZIONI.IDPRENOTAZIONE = PRENOTAZIONESTANDARD.FK_PRENOTAZIONE
                LEFT JOIN PRENOTAZIONELUSSO ON (tipoTaxi='L') AND PRENOTAZIONI.IDPRENOTAZIONE = PRENOTAZIONELUSSO.FK_PRENOTAZIONE
                LEFT JOIN PRENOTAZIONEACCESSIBILE ON (tipoTaxi='A') AND PRENOTAZIONI.IDPRENOTAZIONE = PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE
                where
                    ((tipoTaxi='S' and PRENOTAZIONESTANDARD.FK_PRENOTAZIONE is not null and PRENOTAZIONELUSSO.FK_PRENOTAZIONE is null  and PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE is null )
                        or (tipoTaxi='L' and PRENOTAZIONESTANDARD.FK_PRENOTAZIONE is null and PRENOTAZIONELUSSO.FK_PRENOTAZIONE is not null and PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE is null)
                        or (tipoTaxi='A' and PRENOTAZIONESTANDARD.FK_PRENOTAZIONE is null and PRENOTAZIONELUSSO.FK_PRENOTAZIONE is null and PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE is not null))
                    and (PRENOTAZIONI.STATO = 'pendente')
                    and (PRENOTAZIONI.NPERSONE <= postiTaxi)
                    and PRENOTAZIONI.DATAORA >= currentDate
                    and PRENOTAZIONI.DATAORA <= turno.dataorafine

                    --Filtri
                    and (PRENOTAZIONI.IDPRENOTAZIONE = p_id or p_id is null)
                    and (((to_char(PRENOTAZIONI.DATAORA, 'HH24:MM')) >= replace(p_data1, '%3A', ' ')) or p_data1 is null)
                    and (((to_char(PRENOTAZIONI.DATAORA, 'HH24:MM')) <= replace(p_data2, '%3A', ' ')) or p_data2 is null)
                    and (LOWER(replace(PRENOTAZIONI.LUOGOPARTENZA, ' ', '')) = (LOWER(replace(p_partenza, ' ', ''))) or p_partenza is null)
                    and (PRENOTAZIONI.Npersone = p_persone or p_persone is null)
                    and (LOWER(replace(PRENOTAZIONI.LUOGOARRIVO, ' ', '')) = (LOWER(replace(p_arrivo, ' ', ''))) or p_arrivo is null)
                    and (PRENOTAZIONI.DURATA = p_durata or p_durata is null)

                    order by  case when p_ordina = 'DATAORA' and p_ascdesc='desc'THEN PRENOTAZIONI.DATAORA END  desc,
                        case when p_ordina = 'DATAORA' and p_ascdesc='asc'THEN PRENOTAZIONI.DATAORA END  asc,
                        case when p_ordina = 'DURATA'and p_ascdesc='desc' THEN PRENOTAZIONI.DURATA END desc,
                        case when p_ordina = 'DURATA'and p_ascdesc='asc' THEN PRENOTAZIONI.DURATA END asc,
                        case when p_ordina = 'PARTENZA' and p_ascdesc='desc' THEN PRENOTAZIONI.LUOGOPARTENZA END desc,
                        case when p_ordina = 'PARTENZA' and p_ascdesc='asc' THEN PRENOTAZIONI.LUOGOPARTENZA END asc,
                        case when p_ordina = 'NPERSONE' and p_ascdesc='desc' THEN PRENOTAZIONI.NPERSONE END desc,
                        case when p_ordina = 'NPERSONE' and p_ascdesc='asc' THEN PRENOTAZIONI.NPERSONE END asc,
                        case when p_ordina = 'ARRIVO' and p_ascdesc='desc' THEN PRENOTAZIONI.LUOGOARRIVO END desc,
                        case when p_ordina = 'ARRIVO' and p_ascdesc='asc' THEN PRENOTAZIONI.LUOGOARRIVO END asc,
                        case when p_ordina = 'IDPRENOTAZIONE' and p_ascdesc='desc' THEN PRENOTAZIONI.IDPRENOTAZIONE END desc,
                        case when p_ordina='IDPRENOTAZIONE' and (p_ascdesc=null or p_ascdesc='asc') then PRENOTAZIONI.IDPRENOTAZIONE END asc

                    OFFSET p_offset ROWS
                    FETCH FIRST 30 ROWS ONLY
            )
            loop

                dataOraArrivo:= x.dataOra + NUMTODSINTERVAL (x.durata, 'MINUTE');

                arrayOptionals := gui.StringArray();

                if tipoTaxi = 'L' then
                    for op in (
                        select FK_optionals
                        from richiestePrenLusso where FK_prenotazione=x.idprenotazione
                    ) loop
                        arrayOptionals.extend();
                        arrayOptionals(arrayOptionals.count):=op.FK_optionals;
                    end loop;

                end if;

                -- Controlla se il taxi possiede i giusti posti nel caso del taxi accessibile, se possiede gli optionals nel caso del taxi di lusso
                -- infine controlla se la prenotazione si sovrappone con altre prenotazioni già accettate
                if (((tipoTaxi = 'A' and x.NPERSONEDISABILI <= v_postiTaxiAccess) or tipoTaxi <> 'A') and ((tipoTaxi = 'L' and utility.taxiPossiedeOptionals(turno.fk_taxi, arrayOptionals)) or tipoTaxi <> 'L') and Utility.checkNotPrenotazioniSovrapposte(x.DataOra, dataOraArrivo, turno.FK_TAXI)) then
                    gui.AggiungiRigaTabella();
                        gui.AggiungiElementoTabella('' || x.IDprenotazione || '');
                        gui.AggiungiElementoTabella(x.LuogoPartenza || '');
                        gui.AggiungiElementoTabella((to_char(x.DataOra, 'HH24:MI')));
                        gui.AggiungiElementoTabella('' || x.LuogoArrivo || '');
                        gui.AggiungiElementoTabella('' || x.Npersone || '');
                        gui.AggiungiElementoTabella('' || x.Durata || ' min');

                        if(tipoTaxi = 'A') then
                            gui.AggiungiElementoTabella('' || x.NPERSONEDISABILI || '');
                        end if;

                        -- Pulsante per accettare la prenotazione
                        gui.apriElementoPulsanti;
                            gui.AggiungiPulsanteGenerale(''''||u_root||'.accettaPrenotazione?p_idSess='||p_idSess||'&p_accetta_id='||x.IDprenotazione||'&p_tipo_taxi='||tipoTaxi||'&p_id_taxi='||turno.FK_TAXI||'&p_id_turno='||turno.fk_manager||';'||turno.fk_autista||';'||to_char(turno.dataOraInizio, 'YYYY-MM-DD HH24:MI:SS')||'''', 'Accetta');
                        gui.chiudiElementoPulsanti;

                    gui.ChiudiRigaTabella();
                end if;

            end loop;

        gui.ChiudiTabella('', true);
        gui.ACAPO;

        gui.CHIUDIPAGINA();

        Exception when OTHERS then
            gui.aggiungiPopup(false, 'Qualcosa è andato storto o l'||CHR(39)||'autista non è in servizio');
            gui.CHIUDIPAGINA();

    end visualizzaPrenotazioniPendenti;

    procedure accettaPrenotazione(
        p_idSess            in SESSIONIDIPENDENTI.IDSESSIONE%TYPE default '-1',
        p_accetta_id        in PRENOTAZIONI.IDPRENOTAZIONE%TYPE,
        p_tipo_taxi         in varchar2,
        p_id_taxi           in TAXI.IDTAXI%TYPE,
        p_id_turno          in varchar2
    ) is
        i                   int;
        v_dataOraArrivo     date;
        v_taxi              TAXI%ROWTYPE;
        v_prenotazione      PRENOTAZIONI%ROWTYPE;
        v_turno             TURNI%ROWTYPE;
        v_posti_dis         int;
        v_posti_dis_taxi    int;
        primaryKeyTurno     gui.StringArray;
        arrayOptionals      gui.StringArray := gui.StringArray();
        TaxiERR             EXCEPTION;
        Sovrapposta         EXCEPTION;
        Optionals           EXCEPTION;
        FuoriTurno          EXCEPTION;
        UpdateError         EXCEPTION;
        NoPren              EXCEPTION;
        CURSOR c1 is
            SELECT *
            FROM PRENOTAZIONI
            WHERE IDPRENOTAZIONE = p_accetta_id AND PRENOTAZIONI.STATO = 'pendente'
            FOR UPDATE OF PRENOTAZIONI.STATO;
    begin

        if  SessionHandler.getRuolo(p_idSess) <> 'Autista' then
            raise NoPermessi;
        end if;

        primaryKeyTurno := utility.stringToArray(p_id_turno, ';');

        htp.prn(primaryKeyTurno(3));

        -- Vengono eseguiti tutti i controlli del caso prima di accettare la prenotazione,
        -- Evita di accettare richieste sbagliate o malevole non inviate dal form della procedura "visualizzaPrenotazioniPendenti"

        -- select prenotazioni.* into v_prenotazione from PRENOTAZIONI where idPrenotazione = p_accetta_id;

        -- Controlli sul taxi
        select * into v_taxi from TAXI where IDTAXI = p_id_taxi;

        if(p_tipo_taxi = 'A') then
            select NPERSONEDISABILI into v_posti_dis from PRENOTAZIONEACCESSIBILE where fk_Prenotazione = p_accetta_id;

            select NPERSONEDISABILI into v_posti_dis_taxi from TAXIACCESSIBILE where fk_TAXI = p_id_taxi;
        end if;

        select * into v_turno from TURNI
        where TURNI.FK_MANAGER = to_number(primaryKeyTurno(1), '99')
        and TURNI.FK_AUTISTA = to_number(primaryKeyTurno(2), '99') and to_char(DATAORAINIZIO, 'YYYY-MM-DD HH24:MI:SS') = primaryKeyTurno(3);

        i := 0;

        OPEN c1;
            FETCH c1 INTO v_prenotazione;

            if c1%notfound then

                CLOSE c1;
                raise NoPren;

            elsif v_prenotazione.stato = 'accettata' then

                CLOSE c1;
                raise UpdateError;

            else

                if(v_taxi.stato = 'NonDisponibile' or v_prenotazione.npersone > v_taxi.nposti or (p_tipo_taxi = 'A' and v_posti_dis > p_id_taxi)) then
                    raise TaxiERR;
                end if;

                v_dataOraArrivo := v_prenotazione.dataOra + NUMTODSINTERVAL(v_prenotazione.durata, 'MINUTE');

                if (not Utility.checkNotPrenotazioniSovrapposte(v_prenotazione.DataOra, v_dataOraArrivo, p_id_taxi)) then
                    raise Sovrapposta;
                end if;

                if p_tipo_taxi = 'L' then

                    for op in (
                        select FK_optionals
                        from richiestePrenLusso where FK_prenotazione=p_accetta_id
                        --WHEN NO DATA FOUND????
                    ) loop
                        arrayOptionals.extend();
                        arrayOptionals(arrayOptionals.count):=op.FK_optionals;
                    end loop;

                    if (not utility.taxiPossiedeOptionals(p_id_taxi, arrayOptionals)) then
                        raise Optionals;
                    end if;

                    end if;

                    if (v_turno.dataorainizio > v_prenotazione.dataOra or v_turno.dataorafine < v_prenotazione.dataora) then
                        raise FuoriTurno;
                    end if;


                    UPDATE PRENOTAZIONI
                        SET PRENOTAZIONI.STATO = 'accettata'
                        WHERE CURRENT OF c1;

                    COMMIT;

                end if;

        CLOSE c1;

        i := 0;
        IF (p_tipo_taxi = 'L') THEN
            UPDATE PRENOTAZIONELUSSO
                SET PRENOTAZIONELUSSO.FK_TAXI = p_id_taxi
                WHERE FK_PRENOTAZIONE = p_accetta_id
                      AND FK_TAXI is null ;
            i := SQL%rowcount;
        END IF;

        IF (p_tipo_taxi = 'A') THEN
            UPDATE PRENOTAZIONEACCESSIBILE
                SET PRENOTAZIONEACCESSIBILE.FK_TAXIACCESSIBILE = p_id_taxi
                WHERE FK_PRENOTAZIONE = p_accetta_id
                      AND FK_TAXIACCESSIBILE is null;

            i := SQL%rowcount;
        END IF;

        IF (p_tipo_taxi = 'S') THEN
            UPDATE PRENOTAZIONESTANDARD
                SET PRENOTAZIONESTANDARD.FK_TAXI = p_id_taxi
                WHERE FK_PRENOTAZIONE = p_accetta_id
                AND FK_TAXI is null;
            i := SQL%rowcount;
        END IF;

        if(i = 0) then
            raise UpdateError;
        end if;


        -- Prenotazione accettata con successo
        gui.reindirizza(gruppo1.u_root || '.visPrenAssegnateTaxi?p_idSess='||p_idSess||'&p_id='||p_accetta_id||'&p_accetta=T');

        -- Tutte queste eccezioni portano ad una pagina di errore tranne le ultime due,
        -- perché solo le ultime due possono derivare da una chiamata della procedura "visualizzaPrenotazioniPendenti" definita sopra
        EXCEPTION
            WHEN NoPermessi THEN
                gui.reindirizza(gruppo1.u_root || '.ErrorPage?p_idSess='||p_idSess||'&p_errmsg=Non hai i permessi');
            WHEN TaxiERR THEN
                gui.reindirizza(gruppo1.u_root || '.ErrorPage?p_idSess='||p_idSess||'&p_errmsg=Taxi non disponibile');
            WHEN Sovrapposta THEN
                gui.reindirizza(gruppo1.u_root || '.ErrorPage?p_idSess='||p_idSess||'&p_errmsg=Esiste una prenotazione già accettata sovrapposta');
            WHEN Optionals THEN
                gui.reindirizza(gruppo1.u_root || '.ErrorPage?p_idSess='||p_idSess||'&p_errmsg=Il taxi non soddisfa gli optionals');
            WHEN FuoriTurno THEN
                gui.reindirizza(gruppo1.u_root || '.ErrorPage?p_idSess='||p_idSess||'&p_errmsg=Turno non valido');
            WHEN NoPren THEN
                gui.reindirizza(gruppo1.u_root || '.visualizzaPrenotazioniPendenti?p_idSess='||p_idSess||'&p_id='||p_accetta_id||'&p_accetta=F');
            WHEN UpdateError THEN
                gui.reindirizza(gruppo1.u_root || '.visualizzaPrenotazioniPendenti?p_idSess='||p_idSess||'&p_id='||p_accetta_id||'&p_accetta=F');
    end accettaPrenotazione;

    procedure ErrorPage(
        p_idSess        in SESSIONIDIPENDENTI.IDSESSIONE%TYPE,
        p_errmsg        in varchar2
    ) is
    begin
        gui.apriPagina('Errore', p_idSess);
            gui.aggiungipopup(false, p_errmsg);
        gui.chiudiPagina;
    end ErrorPage;

    procedure visPrenAssegnateTaxi(
        p_idSess            in SESSIONIDIPENDENTI.IDSESSIONE%TYPE default '-1',
        p_id                in PRENOTAZIONI.IDPRENOTAZIONE%TYPE default null,
        p_data1             in varchar2 default null,
        p_data2             in varchar2 default null,
        p_partenza          in PRENOTAZIONI.LUOGOPARTENZA%TYPE default null,
        p_persone           in PRENOTAZIONI.NPERSONE%TYPE default null,
        p_arrivo            in PRENOTAZIONI.LUOGOARRIVO%TYPE default null,
        p_durata            in PRENOTAZIONI.DURATA%TYPE default null,
        p_accetta_id        in PRENOTAZIONI.IDPRENOTAZIONE%TYPE default null,
        p_accetta           in VARCHAR2 default null,
        p_filterSubmit      in varchar2 default null
    ) is
        head                gui.stringArray;
        turno               TURNI%ROWTYPE;
        currentDate         date;
        tipoTaxi            varchar2(1);
        v_posti_A           TAXIACCESSIBILE.NPERSONEDISABILI%TYPE default 0;
        v_fk_taxi_S         TAXISTANDARD.FK_TAXI%TYPE;
        v_posti             TAXI.NPOSTI%TYPE;
    begin

        if (p_filterSubmit = 'R') THEN
            gui.reindirizza(gruppo1.u_root || '.visPrenAssegnateTaxi?p_idSess='||p_idSess);
        end if;

        -- Controllo che si stia cercando di accedere alla procedura con i giusti permessi
        if not SessionHandler.checkRuolo(p_idSess, 'Autista') then
            gui.aggiungiPopup(false, 'Non hai i permessi per visualizzare questa pagina');
            return;
        end if;

        gui.ApriPagina('Prenotazioni Accettate', p_idSess, defaultModal => false);

        gui.acapo();

        gui.AggiungiIntestazione('Visualizza prenotazioni accettate', 'h1');

        gui.acapo();

        /*if (p_filterSubmit = 'T') then
            gui.aggiungiPopup(true, 'Corsa terminata');
        elsif (p_filterSubmit = 'NT') then
            gui.aggiungiPopup(false, 'Corsa non terminata, qualcosa è andato storto');
        end if;*/

        gui.aCapo;

        if (p_accetta = 'T') then
            gui.AggiungiPopup(true, 'Prenotazione('||p_id||') accettata');
        end if;

        gui.aCapo;

        currentDate := SYSDATE;

        SELECT * into turno From TURNI WHERE TURNI.FK_AUTISTA = SessionHandler.GETIDUSER(p_idSess)
                    and Turni.DATAORAINIZIOEFF <= currentDate
                    and Turni.DATAORAFINE >= currentDate;

        gui.ApriFormFiltro(u_root||'.visPrenAssegnateTaxi');
            gui.AggiungiRigaTabella();
                gui.AggiungiCampoFormFiltro('number', 'p_id', p_id, 'ID', minimo => '0');
                gui.AggiungiCampoFormFiltro('text', 'p_partenza', p_partenza, 'Luogo di Partenza');
                gui.AggiungiCampoFormFiltro('text', 'p_arrivo', p_arrivo, 'Luogo di Arrivo');
                gui.AggiungiCampoFormFiltro('time', 'p_data1', p_data1, 'Ora di Partenza (Da)');
                gui.AggiungiCampoFormFiltro('time', 'p_data2', p_data2, 'Ora di Partenza (A)');

                gui.AggiungiCampoFormFiltro('submit', 'p_filterSubmit', 'F', 'Filtra');
            gui.chiudiRigaTabella();

            gui.AggiungiRigaTabella();
                gui.AggiungiCampoFormFiltro('number', 'p_durata', p_durata, 'Durata', minimo => '0');
                gui.AggiungiCampoFormFiltro('number', 'p_persone', p_persone, 'Persone', minimo => '0');
                gui.AGGIUNGIELEMENTOTABELLA('');
                gui.AGGIUNGIELEMENTOTABELLA('');
                gui.AGGIUNGIELEMENTOTABELLA('');
                gui.AggiungiCampoFormFiltro('submit', 'p_filterSubmit', 'R', 'Reset');
            gui.chiudiRigaTabella();

        -- Campo hidden, ID_sessione
        gui.AggiungiCampoFormHidden('number', 'p_idSess', p_idSess);


        gui.chiudiFormFiltro();
        gui.acapo();

        SELECT TAXI.NPOSTI, TAXIACCESSIBILE.NPERSONEDISABILI, TAXISTANDARD.FK_TAXI into v_posti, v_posti_A, v_fk_taxi_S
        FROM TAXI
        LEFT JOIN TAXIACCESSIBILE ON TAXIACCESSIBILE.FK_TAXI = TAXI.IDTAXI
        LEFT JOIN TAXILUSSO ON TAXILUSSO.FK_TAXI = TAXI.IDTAXI
        LEFT JOIN TAXISTANDARD ON TAXISTANDARD.FK_TAXI = TAXI.IDTAXI
        WHERE (TAXI.IDTAXI = turno.FK_TAXI)
              AND ((TAXISTANDARD.FK_TAXI is not null and TAXILUSSO.FK_TAXI is null  and TAXIACCESSIBILE.FK_TAXI is null )
                    or (TAXISTANDARD.FK_TAXI is null and TAXILUSSO.FK_TAXI is not null and TAXIACCESSIBILE.FK_TAXI is null)
                    or (TAXISTANDARD.FK_TAXI is null and TAXILUSSO.FK_TAXI is null and TAXIACCESSIBILE.FK_TAXI is not null));

        -- Controllo del tipo
        if(v_posti_A is not null) then
            tipoTaxi := 'A';
        elsif (v_fk_taxi_S is not null) then
            tipoTaxi := 'S';
        else
            tipoTaxi := 'L';
        end if;

        if tipoTaxi = 'A' then
            head := gui.StringArray('ID', 'Luogo di Partenza', 'Ora di Partenza', 'Luogo di Arrivo',
                                'Persone','Durata', 'Posti per disabili', ' ');
        else
            head := gui.StringArray('ID', 'Luogo di Partenza',  'Ora di Partenza', 'Luogo di Arrivo',
                                'Persone','Durata', ' ');
        end if;

        gui.ApriTabella(head);

        -- Body
        for x in (SELECT PRENOTAZIONI.*, PRENOTAZIONEACCESSIBILE.NPERSONEDISABILI
                FROM
                    PRENOTAZIONI
                LEFT JOIN
                    PRENOTAZIONESTANDARD ON (tipoTaxi = 'S') AND PRENOTAZIONI.IDprenotazione = PRENOTAZIONESTANDARD.FK_Prenotazione
                                            AND PRENOTAZIONESTANDARD.FK_TAXI = turno.fk_taxi
                LEFT JOIN
                    PRENOTAZIONELUSSO ON (tipoTaxi = 'L') AND PRENOTAZIONI.IDprenotazione = PRENOTAZIONELUSSO.FK_Prenotazione
                                            AND PRENOTAZIONELUSSO.FK_TAXI = turno.fk_taxi
                LEFT JOIN
                    PRENOTAZIONEACCESSIBILE ON (tipoTaxi = 'A') AND  PRENOTAZIONI.IDprenotazione = PRENOTAZIONEACCESSIBILE.FK_Prenotazione
                                            AND PRENOTAZIONEACCESSIBILE.FK_TAXIACCESSIBILE = turno.fk_taxi
                LEFT OUTER JOIN
                    CORSEPRENOTATE ON CORSEPRENOTATE.FK_Prenotazione = PRENOTAZIONI.IDPRENOTAZIONE

                where
                    (PRENOTAZIONI.STATO = 'accettata')

                    and (PRENOTAZIONI.DATAORA) >= turno.dataorainizioeff
                    and PRENOTAZIONI.DATAORA <= turno.dataorafine
                    and ((PRENOTAZIONESTANDARD.FK_PRENOTAZIONE is not null and PRENOTAZIONELUSSO.FK_PRENOTAZIONE is null  and PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE is null )
                    or (PRENOTAZIONESTANDARD.FK_PRENOTAZIONE is null and PRENOTAZIONELUSSO.FK_PRENOTAZIONE is not null and PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE is null)
                    or (PRENOTAZIONESTANDARD.FK_PRENOTAZIONE is null and PRENOTAZIONELUSSO.FK_PRENOTAZIONE is null and PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE is not null))

                    -- Controlla che non ci siano corse associate alla prenotazione, in caso vorrebbe dire che è già stata avviata
                    and CORSEPRENOTATE.FK_PRENOTAZIONE is null

                    --Filtri
                    and (PRENOTAZIONI.IDPRENOTAZIONE = p_id or p_id is null)
                    and ((to_char(PRENOTAZIONI.DataOra, 'HH24:MI') >= replace(p_data1, '%3A', ':')) or p_data1 is null)
                    and ((to_char(PRENOTAZIONI.DataOra, 'HH24:MI') <= replace(p_data2, '%3A', ':')) or p_data2 is null)
                    and (LOWER(replace(PRENOTAZIONI.LUOGOPARTENZA, ' ', '')) = (LOWER(replace(p_partenza, ' ', ''))) or p_partenza is null)
                    and (PRENOTAZIONI.Npersone = p_persone or p_persone is null)
                    and (LOWER(replace(PRENOTAZIONI.LUOGOARRIVO, ' ', '')) = (LOWER(replace(p_arrivo, ' ', ''))) or p_arrivo is null)
                    and (PRENOTAZIONI.DURATA = p_durata or p_durata is null)
            )
            loop
                gui.AggiungiRigaTabella();
                    gui.AggiungiElementoTabella('' || x.IDprenotazione || '');
                    gui.AggiungiElementoTabella(x.LuogoPartenza || '');
                    gui.AggiungiElementoTabella((to_char(x.DataOra, 'HH24:MI')));
                    gui.AggiungiElementoTabella('' || x.LuogoArrivo || '');
                    gui.AggiungiElementoTabella('' || x.Npersone || '');
                    gui.AggiungiElementoTabella('' || x.Durata || ' min');

                    if x.NPERSONEDISABILI is not null then
                        gui.AggiungiElementoTabella('' || x.NPERSONEDISABILI || '');
                    end if;


                    gui.apriModalPopup('Avvia Corsa', 'modal_'||x.idprenotazione||'');
                        -- Boh form che non andrà mai
                        gui.aggiungiForm(url => u_root||'.avviaCorsa');
                            gui.AggiungiCampoFormHidden('number', 'p_idSess', p_idSess);
                            gui.AggiungiCampoFormHidden('number', 'p_prenotazione', x.idprenotazione);

                                gui.aggiungiGruppoInput;
                                    gui.aggiungilabel(target => 'p_passeggeri', testo => 'Passeggeri');
                                    gui.AggiungiInput(tipo => 'number', nome => 'p_passeggeri', required => true, value => ''||x.NPERSONE||'', minimo => '1', massimo => ''||(v_posti+v_posti_A)||'');
                                gui.chiudiGruppoInput;

                                gui.aggiungiGruppoInput;
                                    gui.aggiungiBottoneSubmit('Avvia');
                                gui.chiudiGruppoInput;
                        gui.chiudiForm;
                    gui.chiudiModalPopup;

                    -- Bottone avvio corsa
                    gui.apriElementoPulsanti;
                        gui.aggiungiPulsanteGenerale(''''||u_root||'.AvviaCorsa?p_idSess='||p_idSess||'&p_id_prenotazione='||x.IDprenotazione||'&p_id_taxi='||turno.fk_taxi||'''', 'Avvia', 'modal_'||x.idprenotazione);
                    gui.chiudiElementoPulsanti;

                gui.ChiudiRigaTabella();
            end loop;

        gui.ChiudiTabella();
        htp.prn('<br>');

        gui.CHIUDIPAGINA();

        Exception when OTHERS then
            gui.aggiungiPopup(false, 'Qualcosa è andato storto o l'||CHR(39)||'autista non è in servizio');
            gui.CHIUDIPAGINA();

    end visPrenAssegnateTaxi;

    procedure visCorseTaxiRiferiti(
        p_idSess            in SESSIONIDIPENDENTI.IDSESSIONE%TYPE default '-1',
        p_id_prenotazione   in CORSEPRENOTATE.FK_PRENOTAZIONE%TYPE default null,
        p_data1             in varchar2 default null,
        p_data2             in varchar2 default null,
        p_persone           in CORSEPRENOTATE.PASSEGGERI%TYPE default null,
        p_durata            in CORSEPRENOTATE.DURATA%TYPE default null,
        p_km                in CORSEPRENOTATE.KM%TYPE default null,
        p_importo           in CORSEPRENOTATE.IMPORTO%TYPE default null,
        p_tipo              in varchar2 default null,
        p_ordina            in varchar2 default null,
        p_ascdesc           in varchar2 default null,
        p_filterSubmit      in varchar2 default null,
        p_msgVisCorsePren   in number default null,
        p_offset            int default 0
    ) is
        head                gui.stringArray;
        v_id_referente      TAXI.FK_REFERENTE%TYPE;
        dataOraArrivo       CORSEPRENOTATE.DATAORA%TYPE;
    begin

        if (p_filterSubmit = 'R') THEN
            gui.reindirizza(gruppo1.u_root || '.visCorseTaxiRiferiti?p_idSess='||p_idSess);
            return;
        end if;

        if not SessionHandler.checkRuolo(p_idSess, 'Autista') then
            gui.aggiungiPopup(false, 'Non hai i permessi per visualizzare questa pagina');
            return;
        end if;

        v_id_referente := SessionHandler.GETIDUSER(p_idSess);

        head := gui.StringArray('ID', 'Data di Partenza', 'Ora di Partenza', 'Durata', 'Importo','Passeggeri', 'KM', 'Categoria', ' ');

        gui.ApriPagina('Corse Prenotate', p_idSess);
        gui.acapo;
        gui.AggiungiIntestazione('Visualizza corse prenotate taxi riferiti', 'h1');
        gui.acapo;

        if (p_msgVisCorsePren = 0) then
            gui.aggiungiPopup(false, 'Corsa non modificata');
        elsif (p_msgVisCorsePren = 1) then
            gui.aggiungiPopup(true, 'Corsa modificata con successo!');
        end if;

        gui.aCapo(2);

        gui.ApriFormFiltro(u_root||'.visCorseTaxiRiferiti');
            gui.AggiungiRigaTabella();

                gui.AggiungiCampoFormFiltro('number', 'p_id_prenotazione', p_id_prenotazione, 'ID');
                gui.AggiungiCampoFormFiltro('datetime-local', 'p_data1', p_data1, 'Data e ora di Partenza (Da)');
                gui.AggiungiCampoFormFiltro('datetime-local', 'p_data2', p_data2, 'Data e ora di Partenza (A)');
                gui.AggiungiCampoFormFiltro('number', 'p_persone', p_persone, 'Passeggeri');

                gui.ApriSelectFormFiltro('p_ordina', 'Campo da ordinare');
                    gui.AggiungiOpzioneSelect('IDPRENOTAZIONE', p_ordina = 'IDPRENOTAZIONE', 'ID');
                    gui.AggiungiOpzioneSelect('DATAORA', p_ordina = 'DATAORA', 'Data e ora');
                    gui.AggiungiOpzioneSelect('DURATA', p_ordina = 'DURATA', 'Durata');
                    gui.AggiungiOpzioneSelect('IMPORTO', p_ordina = 'IMPORTO', 'Importo');
                    gui.AggiungiOpzioneSelect('PASSEGGERI', p_ordina = 'PASSEGGERI', 'Passeggeri');
                    gui.AggiungiOpzioneSelect('KM', p_ordina = 'KM', 'KM');
                gui.ChiudiSelectFormFiltro();

                gui.AggiungiCampoFormFiltro('submit', 'p_filterSubmit', 'P', 'Filtra');

            gui.chiudiRigaTabella();

            gui.AggiungiRigaTabella();

                gui.AggiungiCampoFormFiltro('number', 'p_durata', p_durata, 'Durata');
                gui.AggiungiCampoFormFiltro('number', 'p_km', p_km, 'KM');
                gui.AggiungiCampoFormFiltro('number', 'p_importo', p_importo, 'Importo');


                gui.ApriSelectFormFiltro('p_tipo', 'Categoria');
                    gui.AggiungiOpzioneSelect('S', p_tipo = 'S', 'Standard');
                    gui.AggiungiOpzioneSelect('A', p_tipo = 'A', 'Accessibile');
                    gui.AggiungiOpzioneSelect('L', p_tipo = 'L', 'Lusso');
                gui.ChiudiSelectFormFiltro();

                gui.ApriSelectFormFiltro('p_ascdesc', 'Ordinamento');
                    gui.AggiungiOpzioneSelect('asc', p_ascdesc = 'asc', 'Crescente');
                    gui.AggiungiOpzioneSelect('desc', p_ascdesc = 'desc', 'Decrescente');
                gui.ChiudiSelectFormFiltro();

                --gui.aggiungiElementoTabella();

                gui.AggiungiCampoFormFiltro('submit', 'p_filterSubmit', 'R', 'Reset');

                gui.chiudiRigaTabella();

            -- Campo hidden, ID_sessione
            gui.AggiungiCampoFormHidden('number', 'p_idSess', p_idSess);

        gui.chiudiFormFiltro();

        htp.prn('<br>');

        gui.ApriTabella(head);

        for x in (SELECT
                    CorsePrenotate.*,
                    PRENOTAZIONESTANDARD.FK_PRENOTAZIONE p_s,
                    PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE p_a,
                    PRENOTAZIONELUSSO.FK_PRENOTAZIONE p_l
                FROM
                    CorsePrenotate
                LEFT JOIN
                    PRENOTAZIONESTANDARD ON ((p_tipo='S') or p_tipo is null) and CorsePrenotate.FK_PRENOTAZIONE = PRENOTAZIONESTANDARD.FK_PRENOTAZIONE
                LEFT JOIN
                    PRENOTAZIONELUSSO ON ((p_tipo='L')  or p_tipo is null) and CorsePrenotate.FK_PRENOTAZIONE = PRENOTAZIONELUSSO.FK_PRENOTAZIONE
                LEFT JOIN
                    PRENOTAZIONEACCESSIBILE ON ((p_tipo='A')  or p_tipo is null) and CorsePrenotate.FK_PRENOTAZIONE = PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE

                WHERE
                    (( ((p_tipo='S') or p_tipo is null) and PRENOTAZIONESTANDARD.FK_PRENOTAZIONE is not null and PRENOTAZIONELUSSO.FK_PRENOTAZIONE is null and PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE is null)
                    or ( ((p_tipo='L') or p_tipo is null) and PRENOTAZIONESTANDARD.FK_PRENOTAZIONE is null and PRENOTAZIONELUSSO.FK_PRENOTAZIONE is not null and PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE is null)
                    or ( ((p_tipo='A') or p_tipo is null) and PRENOTAZIONESTANDARD.FK_PRENOTAZIONE is null and PRENOTAZIONELUSSO.FK_PRENOTAZIONE is null and PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE is not null))

                    and (PRENOTAZIONESTANDARD.FK_TAXI in (SELECT TAXI.IDTAXI FROM TAXI WHERE TAXI.FK_Referente = v_id_referente) or
                         PRENOTAZIONELUSSO.FK_TAXI in (SELECT TAXI.IDTAXI FROM TAXI WHERE TAXI.FK_Referente = v_id_referente) or
                         PRENOTAZIONEACCESSIBILE.FK_TAXIACCESSIBILE in (SELECT TAXI.IDTAXI FROM TAXI WHERE TAXI.FK_Referente = v_id_referente))

                    and ((CorsePrenotate.FK_PRENOTAZIONE = p_id_prenotazione or p_id_prenotazione is null )
                    and (((to_char(CorsePrenotate.DATAORA, 'YYYY-MM-DD HH24:MM')) >= replace(p_data1, 'T', ' ')) or p_data1 is null)
                    and (((to_char(CorsePrenotate.DATAORA, 'YYYY-MM-DD HH24:MM')) <= replace(p_data2, 'T', ' ')) or p_data2 is null)
                    and (CORSEPRENOTATE.IMPORTO = p_importo or p_importo is null)
                    and (CORSEPRENOTATE.DURATA = p_durata or p_durata is null)
                    and (CORSEPRENOTATE.KM = p_km or p_km is null))

                    order by  case when p_ordina = 'DATAORA' and p_ascdesc='desc'THEN CorsePrenotate.DATAORA END  desc,
                        case when p_ordina = 'DATAORA' and p_ascdesc='asc'THEN CorsePrenotate.DATAORA END  asc,
                        case when p_ordina = 'DURATA'and p_ascdesc='desc' THEN CorsePrenotate.DURATA END desc,
                        case when p_ordina = 'DURATA'and p_ascdesc='asc' THEN CorsePrenotate.DURATA END asc,
                        case when p_ordina = 'IMPORTO' and p_ascdesc='desc' THEN CorsePrenotate.IMPORTO END desc,
                        case when p_ordina = 'IMPORTO' and p_ascdesc='asc' THEN CorsePrenotate.IMPORTO END asc,
                        case when p_ordina = 'PASSEGGERI' and p_ascdesc='desc' THEN CorsePrenotate.PASSEGGERI END desc,
                        case when p_ordina = 'PASSEGGERI' and p_ascdesc='asc' THEN CorsePrenotate.PASSEGGERI END asc,
                        case when p_ordina = 'KM' and p_ascdesc='desc' THEN CorsePrenotate.KM END desc,
                        case when p_ordina = 'KM' and p_ascdesc='asc' THEN CorsePrenotate.KM END asc,
                        case when p_ordina = 'IDPRENOTAZIONE' and p_ascdesc='desc' THEN CorsePrenotate.FK_PRENOTAZIONE END desc,
                        case when p_ordina='IDPRENOTAZIONE' and (p_ascdesc=null or p_ascdesc='asc') then CorsePrenotate.FK_PRENOTAZIONE END asc

                OFFSET p_offset ROWS
                FETCH FIRST 30 ROWS ONLY
            )
            loop
                gui.AggiungiRigaTabella();
                    gui.AggiungiElementoTabella('' || x.FK_PRENOTAZIONE || '');
                    gui.AggiungiElementoTabella('' || x.DataOra || '');
                    gui.AggiungiElementoTabella((to_char(x.DataOra, 'HH24:MI')));
                    gui.AggiungiElementoTabella('' || x.Durata || ' min');
                    gui.AggiungiElementoTabella('' || x.importo || '€');
                    gui.AggiungiElementoTabella('' || x.Passeggeri || '');

                gui.AggiungiElementoTabella('' || x.KM || '');

                if x.p_a is not null then
                    gui.AggiungiElementoTabella('Accessibile');
                elsif x.p_s is not null then
                    gui.AggiungiElementoTabella('Standard');
                elsif x.p_l is not null then
                    gui.AggiungiElementoTabella('Lusso');
                end if;

                dataOraArrivo := x.dataOra + NUMTODSINTERVAL(x.durata, 'MINUTE') + NUMTODSINTERVAL (30, 'MINUTE');

                    gui.apriElementoPulsanti;
                        if dataOraArrivo >= CURRENT_DATE then
                            gui.AggiungiPulsanteModifica(u_root||'.modificaCorsaPrenotata?p_idSess='||p_idSess||'&p_id='||x.FK_PRENOTAZIONE||'&p_url='||u_root||'.visCorseTaxiRiferiti?p_idSess='||p_idSess||'');
                        end if;
                    gui.chiudiElementoPulsanti;

                gui.ChiudiRigaTabella();
            end loop;
        gui.ChiudiTabella('', true);
        gui.ACAPO();
        gui.CHIUDIPAGINA();

        Exception when OTHERS then
            gui.aggiungiPopup(false, 'Qualcosa è andato storto');
            gui.CHIUDIPAGINA();

    end visCorseTaxiRiferiti;

    procedure modificaCorsaPrenotata(
        p_idSess            in SESSIONIDIPENDENTI.IDSESSIONE%TYPE default '-1',
        p_id                in CORSEPRENOTATE.FK_PRENOTAZIONE%TYPE default null,
        p_km                in CORSEPRENOTATE.KM%TYPE default null,
        p_passeggeri        in CORSEPRENOTATE.PASSEGGERI%TYPE default null,
        p_url               in varchar2 default null
    )is
        i                   int;
        corsa               CORSEPRENOTATE%ROWTYPE;
        v_fineTurno         TURNI.DATAORAFINE%TYPE;
        v_km                CORSEPRENOTATE.KM%TYPE;
        v_passeggeri        CORSEPRENOTATE.PASSEGGERI%TYPE;
    begin

        if not SessionHandler.checkRuolo(p_idSess, 'Autista') then
            gui.aggiungiPopup(false, 'Non hai i permessi per visualizzare questa pagina');
            gui.chiudiPagina;
            return;
        end if;

        gui.apriPagina('Modifica Corsa Prenotata',p_idSess);

        gui.aggiungiIntestazione('Modifica Corsa Prenotata');

        gui.aCapo(2);

        SELECT * into corsa FROM CORSEPRENOTATE WHERE FK_PRENOTAZIONE = p_id;

        select TU.DATAORAFINE into v_fineTurno
         from Taxi Ta, Turni Tu, Prenotazioni P, CorsePrenotate C
            left join PrenotazioneStandard PrenS on C.FK_Prenotazione=PrenS.FK_Prenotazione
            left join PrenotazioneAccessibile PrenA on C.FK_Prenotazione=PrenA.FK_Prenotazione
            left join PrenotazioneLusso PrenL on C.FK_Prenotazione=PrenL.FK_Prenotazione
        where C.FK_Prenotazione=P.IDprenotazione AND P.IDPRENOTAZIONE=p_id
          and Tu.FK_Taxi = Ta.IDtaxi
          AND C.DataOra >= Tu.DataOraInizioEff
          AND C.DataOra <= Tu.DataOraFineEff
          and (PrenS.FK_Taxi = Ta.IDtaxi OR PrenA.FK_TaxiAccessibile = Ta.IDtaxi OR PrenL.FK_Taxi = Ta.IDtaxi);

        -- Corsa non terminata
        if corsa.durata is null then
            gui.aggiungiPopup(false, 'Questa prenotazione non si può ancora modificare');
            gui.chiudiPagina;
            return;
        end if;

        -- Aggiunge un giorno alla fine del turno
        v_fineTurno := v_fineTurno+1 ;


        if v_fineTurno >= CURRENT_DATE then

            -- Esegue l'update dopo aver controllato tutti i vincoli,
            -- Se p_km è nullo vuol dire che non è stata richiesta ancora nessuna modifica
            if (p_km is not null and p_km > 0) and (p_passeggeri is not null and p_passeggeri > 0) then

                -- Se il nuovo campo è uguale al vecchio evito di fare l'update
                if corsa.km = p_km and corsa.passeggeri = p_passeggeri then

                    if p_url is not null then
                        gui.reindirizza(p_url||'&p_msgVisCorsePren=0&p_id_prenotazione='||p_id||'');
                        return;
                    end if;

                    gui.AGGIUNGIPOPUP(false, 'Chilometri e passeggeri non modificati, valore invariato');
                    gui.acapo;
                    v_km := corsa.km;
                    v_passeggeri := corsa.passeggeri;

                else

                    UPDATE CORSEPRENOTATE
                        SET KM = p_km, PASSEGGERI = p_passeggeri
                        WHERE FK_PRENOTAZIONE = p_id;
                    i := SQL%rowcount;

                    if p_url is not null then
                        if i > 0 then
                            gui.reindirizza(p_url||'&p_msgVisCorsePren=1&p_id_prenotazione='||p_id||'');
                            return;
                        else
                            gui.reindirizza(p_url||'&p_msgVisCorsePren=0&p_id_prenotazione='||p_id||'');
                            return;
                        end if;
                    end if;

                    if i > 0 then
                        gui.AGGIUNGIPOPUP(true, 'Chilometri modificati con successo');
                        v_km := p_km;
                        v_passeggeri := p_passeggeri;
                    else
                        gui.AGGIUNGIPOPUP(false, 'Chilometri non modificati, qualcosa è andato storto');
                        v_km := corsa.km;
                        v_passeggeri := corsa.passeggeri;
                    end if;

                    gui.acapo;
                end if;
            else
                v_km := corsa.km;
                v_passeggeri := corsa.passeggeri;
            end if;

            -- Carica il form per modificare la corsa, richiama se stessa ma con p_km impostato
            gui.aggiungiForm(url =>u_root||'.modificaCorsaPrenotata');
					gui.AGGIUNGIINTESTAZIONE('Modifica corsa '||p_id||'', 'h2');
						gui.aggiungiGruppoInput;
                            gui.AGGIUNGICAMPOFORMHIDDEN('text', 'p_idSess', p_idSess);
                            gui.AGGIUNGICAMPOFORMHIDDEN('number', 'p_id', p_id);
                            gui.AGGIUNGICAMPOFORMHIDDEN('text', 'p_url', p_url);

                            gui.aggiungiLabel('p_km', 'Chilometri percorsi');
							gui.aggiungiCampoForm(tipo => 'number', value => ''||v_km||'', nome => 'p_km', placeholder => 'Chilometri percorsi', minimo => '0');

                            gui.aggiungiLabel('p_passeggeri', 'Passeggeri');
							gui.aggiungiCampoForm(tipo => 'number', value => ''||v_passeggeri||'', nome => 'p_passeggeri', placeholder => 'Passeggeri', minimo => '0');
						gui.chiudiGruppoInput;
                    gui.aggiungiGruppoInput;
                        gui.AGGIUNGIBOTTONESUBMIT('Modifica');
                    gui.chiudiGruppoInput;
            gui.chiudiForm;

        else
            gui.aggiungipopup(false, 'Questa prenotazione non si può più modificare');
        end if;

        gui.chiudiPagina;

        EXCEPTION
            WHEN OTHERS THEN
                gui.aggiungiPopup(false, 'Qualcosa è andato storto o la corsa è inesistente');
                gui.chiudiPagina;

    end modificaCorsaPrenotata;
    procedure StatCorseMaiEffettuate(
        p_idSess            in SESSIONIDIPENDENTI.IDSESSIONE%TYPE default '-1'
    ) is
        head                gui.stringArray;
        i                   int := 0;
    begin

        if not SessionHandler.checkRuolo(p_idSess, 'Manager') then
            gui.aggiungiPopup(false, 'Non hai i permessi per visualizzare questa pagina');
            return;
        end if;

        gui.apriPagina('Corse mai effettuate',p_idSess);

        gui.aggiungiIntestazione('Statistiche prenotazioni senza una corsa', 'h1');
        gui.acapo(3);
        gui.aggiungiParagrafo('Le statistiche sono aggiornate fino al giorno '||to_char(CURRENT_DATE-1, 'DD/MM/YYYY')||'.');
        gui.acapo();

        htp.prn('<br>');

        head := gui.StringArray('Stato','Totale', 'Standard','Accessibile','Lusso', ' ');

        -- Body
        for x in ( SELECT (CASE
            WHEN NONANONIME.FK_PRENOTAZIONE is not null and NONANONIME.FK_OPERATORE is not null THEN 'NonAnonimeTelefoniche'
            WHEN NONANONIME.FK_PRENOTAZIONE is not null and NONANONIME.FK_OPERATORE is null THEN 'Online'
            ELSE 'AnonimeTelefoniche'
            END) TIPO, count(*) totale, count(case when Corseprenotate.FK_PRENOTAZIONE is null then 1 end) corse_non_effettuate,

            count(CASE WHEN PRENOTAZIONI.stato = 'annullata' and PRENOTAZIONESTANDARD.FK_PRENOTAZIONE is not null then 1 end) annullate_standard,
            count(CASE WHEN PRENOTAZIONI.stato = 'accettata' and PRENOTAZIONESTANDARD.FK_PRENOTAZIONE is not null and Corseprenotate.FK_PRENOTAZIONE is null then 1 end) accettate_standard,
            count(CASE WHEN PRENOTAZIONI.stato = 'rifiutata' and PRENOTAZIONESTANDARD.FK_PRENOTAZIONE is not null then 1 end) rifiutate_standard,

            count(CASE WHEN PRENOTAZIONI.stato = 'annullata' and PRENOTAZIONEaccessibile.FK_PRENOTAZIONE is not null then 1 end) annullate_accessibile,
            count(CASE WHEN PRENOTAZIONI.stato = 'accettata' and PRENOTAZIONEaccessibile.FK_PRENOTAZIONE is not null and Corseprenotate.FK_PRENOTAZIONE is null then 1 end) accettate_accessibile,
            count(CASE WHEN PRENOTAZIONI.stato = 'rifiutata' and PRENOTAZIONEaccessibile.FK_PRENOTAZIONE is not null then 1 end) rifiutate_accessibile,

            count(CASE WHEN PRENOTAZIONI.stato = 'annullata' and PRENOTAZIONElusso.FK_PRENOTAZIONE is not null then 1 end) annullate_lusso,
            count(CASE WHEN PRENOTAZIONI.stato = 'accettata' and PRENOTAZIONElusso.FK_PRENOTAZIONE is not null and Corseprenotate.FK_PRENOTAZIONE is null then 1 end) accettate_lusso,
            count(CASE WHEN PRENOTAZIONI.stato = 'rifiutata' and PRENOTAZIONElusso.FK_PRENOTAZIONE is not null then 1 end) rifiutate_lusso

            FROM PRENOTAZIONI
            LEFT JOIN NonAnonime ON PRENOTAZIONI.IDPRENOTAZIONE = NonAnonime.FK_PRENOTAZIONE
            LEFT JOIN AnonimeTelefoniche ON PRENOTAZIONI.IDPRENOTAZIONE = AnonimeTelefoniche.FK_PRENOTAZIONE
            LEFT JOIN PRENOTAZIONESTANDARD ON PRENOTAZIONI.IDPRENOTAZIONE = PRENOTAZIONESTANDARD.FK_PRENOTAZIONE
            LEFT JOIN PRENOTAZIONELUSSO ON PRENOTAZIONI.IDPRENOTAZIONE = PRENOTAZIONELUSSO.FK_PRENOTAZIONE
            LEFT JOIN PRENOTAZIONEACCESSIBILE ON PRENOTAZIONI.IDPRENOTAZIONE = PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE
            LEFT OUTER JOIN Corseprenotate ON Corseprenotate.FK_PRENOTAZIONE = PRENOTAZIONI.IDPRENOTAZIONE
            where
                (( PRENOTAZIONESTANDARD.FK_PRENOTAZIONE is not null and PRENOTAZIONELUSSO.FK_PRENOTAZIONE is null  and PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE is null )
                    or (PRENOTAZIONESTANDARD.FK_PRENOTAZIONE is null and PRENOTAZIONELUSSO.FK_PRENOTAZIONE is not null and PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE is null)
                    or (PRENOTAZIONESTANDARD.FK_PRENOTAZIONE is null and PRENOTAZIONELUSSO.FK_PRENOTAZIONE is null and PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE is not null))
                and ((NonAnonime.FK_PRENOTAZIONE is null and AnonimeTelefoniche.FK_PRENOTAZIONE is not null)
                    or (NonAnonime.FK_PRENOTAZIONE is not null and AnonimeTelefoniche.FK_PRENOTAZIONE is null))


                and PRENOTAZIONI.stato <> 'pendente'
                and PRENOTAZIONI.DATAORA < CURRENT_DATE

                Group by CASE
                        WHEN NONANONIME.FK_PRENOTAZIONE is not null and NONANONIME.FK_OPERATORE is not null THEN 'NonAnonimeTelefoniche'
                        WHEN NONANONIME.FK_PRENOTAZIONE is not null and NONANONIME.FK_OPERATORE is null THEN 'Online'
                        ELSE 'AnonimeTelefoniche'
                        END
            )
            loop
                i := i +1;

                case
                    when x.TIPO = 'Online' then
                        gui.aggiungiIntestazione('Prenotazioni Online', 'h3');
                    when x.TIPO = 'NonAnonimeTelefoniche' then
                        gui.aggiungiIntestazione('Prenotazioni Telefoniche', 'h3');
                    else
                        gui.aggiungiIntestazione('Prenotazioni Telefoniche Anonime', 'h3');
                end case;

                gui.aggiungiChart('myChart'||i||'','
                {
                    type: "scatter",
                    data: {
                    labels: [
                        "Accettate",
                        "Cancellate",
                        "Rifiutate"
                    ],
                    datasets: [{
                        type: "bar",
                        label: "Standard",
                        data: ['||x.accettate_standard||','||x.annullate_standard||','||x.rifiutate_standard||'],
                        borderColor: "rgb(255, 196, 54)",
                        backgroundColor: "rgba(225, 196, 54, 0.6)"
                    }, {
                        type: "bar",
                        label: "Accessibili",
                        data: ['||x.accettate_accessibile||','||x.annullate_accessibile||','||x.rifiutate_accessibile||'],
                        fill: false,
                        borderColor: "rgb(225, 179, 54)",
                        backgroundColor: "rgba(225, 179, 54, 0.6)"
                    }, {
                        type: "bar",
                        label: "Lusso",
                        data: ['||x.accettate_lusso||','||x.annullate_lusso||','||x.rifiutate_lusso||'],
                        fill: false,
                        borderColor: "rgb(229, 216, 154)",
                        backgroundColor: "rgba(229, 216, 154, 0.6)"
                    }]
                    },
                    options: {
                        scales: {
                        y: {
                            beginAtZero: true
                        }
                        }
                    }
                }');

                gui.acapo(3);
            end loop;

        gui.acapo(3);

        gui.chiudiPagina;

        EXCEPTION
            WHEN OTHERS THEN
                gui.chiudiPagina;


    end StatCorseMaiEffettuate;

--------------------------------Caporale--------------------------------------
--------------------------------visPrenPenFut--------------------------------------
    procedure visPrenPenFut (
        p_id in PRENOTAZIONI.IDprenotazione%TYPE default null,
        p_data_min varchar2 default null,
        p_data_max varchar2 default null,
        p_ora_min varchar2 default null,
        p_ora_max varchar2 default null,
        p_partenza in PRENOTAZIONI.LuogoPartenza%TYPE default null,
        p_persone_min in PRENOTAZIONI.Npersone%TYPE default null,
        p_persone_max in PRENOTAZIONI.Npersone%TYPE default null,
        p_arrivo in PRENOTAZIONI.LuogoArrivo%TYPE default null,
        p_durata_min in PRENOTAZIONI.Durata%TYPE default null,
        p_durata_max in PRENOTAZIONI.Durata%TYPE default null,
        p_modificata in PRENOTAZIONI.Modificata%TYPE default null,
        p_categoria varchar2 default null,
        p_idSess in SESSIONIDIPENDENTI.IDSESSIONE%TYPE default null
    )
    is
    head gui.StringArray;
    v_todayDateTime date;
    v_oraPrimoTurnoNonAttivo date;

    begin

        gui.ApriPagina('Prenotazioni pendenti future', p_idSess);

        v_todayDateTime := SYSDATE;
        gui.aCapo();
        gui.AggiungiIntestazione('Prenotazioni in un turno futuro', 'h1');

        if SessionHandler.getRuolo(p_idSess) is null OR SessionHandler.getRuolo(p_idSess)<>'Operatore'
        then raise NoPermessi;
        end if;

        gui.aCapo(2);

        -- form per i filtri
        gui.ApriFormFiltro(u_root||'.visPrenPenFut');
        gui.AggiungiCampoFormFiltro('number', 'p_id', p_id, 'ID', minimo=>1);
        gui.AggiungiCampoFormFiltro('text', 'p_partenza', p_partenza, 'Luogo di Partenza');
        gui.AggiungiCampoFormFiltro('date', 'p_data_min', p_arrivo, 'Data Min');
        gui.AggiungiCampoFormFiltro('date', 'p_data_max', p_data_max, 'Data Max');
        gui.AggiungiRigaTabella();

        gui.AggiungiCampoFormFiltro('time', 'p_ora_min', p_ora_min, 'Ora Min');
        gui.AggiungiCampoFormFiltro('time', 'p_ora_max', p_ora_max, 'Ora Max');
        gui.AggiungiCampoFormFiltro('text', 'p_arrivo', p_arrivo, 'Luogo di Arrivo');
        gui.AggiungiCampoFormFiltro('number', 'p_persone_min', p_persone_min, 'Persone Min', minimo=>1, massimo=>8);
        gui.AggiungiRigaTabella();

        gui.AggiungiCampoFormFiltro('number', 'p_persone_max', p_persone_max, 'Persone Max', minimo=>1, massimo=>8);

        gui.ApriSelectFormFiltro('p_modificata', 'Modificata');
        gui.AggiungiOpzioneSelect('1', case p_modificata when 1 then true else false end, 'sì');
        gui.AggiungiOpzioneSelect('0', case p_modificata when 0 then true else false end, 'no');

        gui.ChiudiSelectFormFiltro;

        gui.AggiungiCampoFormFiltro('number', 'p_durata_min', p_durata_min, 'Durata Min', minimo=>1);
        gui.AggiungiCampoFormFiltro('number', 'p_durata_max', p_durata_max, 'Durata Max', minimo=>1);

        gui.AggiungiRigaTabella();

        gui.ApriSelectFormFiltro('p_categoria', 'Categoria');
        gui.AggiungiOpzioneSelect('Standard', case p_categoria when 'Standard' then true else false end, 'Standard');
        gui.AggiungiOpzioneSelect('Accessibile', case p_categoria when 'Accessibile' then true else false end, 'Accessibile');
        gui.AggiungiOpzioneSelect('Lusso', case p_categoria when 'Lusso' then true else false end, 'Lusso');
        gui.ChiudiSelectFormFiltro;

        gui.AggiungiCampoFormHidden('text', 'p_idSess', p_idSess);

        gui.AggiungiCampoFormFiltro('submit', '', '', 'Filtra');
        gui.ChiudiFormFiltro();

        gui.ApriFormFiltro(u_root||'.visPrenPenFut');
        gui.AggiungiCampoFormHidden('text', 'p_idSess', p_idSess);
        gui.AggiungiCampoFormFiltro('submit', '', '', 'Reset filtro');
        gui.ChiudiFormFiltro();

        gui.aCapo();

        -- se ci sono dei turni attivi (condizione where), l'ora in cui iniziano ad esserci turni non attivi
        -- è quando finisce il turno che finisce più tardi
        select max(Tu1.DataOraFine)
        into v_oraPrimoTurnoNonAttivo
        from Turni Tu1
        where Tu1.DataOraInizio < v_todayDateTime and
        Tu1.DataOraFine > v_todayDateTime;

        -- se non ci sono turni attivi, tutte le prenotazioni da ora (sysdate) in poi
        -- sono in un turno non attivo
        if v_oraPrimoTurnoNonAttivo IS NULL
        then v_oraPrimoTurnoNonAttivo := v_todayDateTime;
        end if;

        head := gui.StringArray('ID', 'Luogo di Partenza', 'Data di Partenza', 'Ora di Partenza', 'Luogo di Arrivo',
                            'Persone', 'Modificata','Durata', 'Categoria', ' ');
        gui.ApriTabella(head, ident=>'1');

        for x in (
            select P.*, PrenS.FK_Prenotazione as PrenStd, PrenA.FK_Prenotazione as PrenAcc, PrenL.FK_Prenotazione as PrenLusso
            from Prenotazioni P
            left join PrenotazioneStandard PrenS on P.IDprenotazione=PrenS.FK_Prenotazione
            left join PrenotazioneAccessibile PrenA on P.IDprenotazione=PrenA.FK_Prenotazione
            left join PrenotazioneLusso PrenL on P.IDprenotazione=PrenL.FK_Prenotazione
            where
            P.Stato = 'pendente' AND
            P.DataOra >= v_oraPrimoTurnoNonAttivo
            AND --condizioni per il filtraggio
            (P.IDprenotazione = p_id or p_id is null) AND
            ((trunc(P.DataOra) >= to_date(p_data_min, 'YYYY-MM-DD')) or p_data_min is null) AND
            ((trunc(P.DataOra) <= to_date(p_data_max, 'YYYY-MM-DD')) or p_data_max is null) AND
            (to_char(P.DataOra, 'HH24:MI') >= p_ora_min or p_ora_min is null) AND
            (to_char(P.DataOra, 'HH24:MI') <= p_ora_max or p_ora_max is null) AND
            (LOWER(replace(P.LuogoPartenza, ' ', '')) = (LOWER(replace(p_partenza, ' ', ''))) OR p_partenza is null) AND
            (P.Npersone >= p_persone_min or p_persone_min is null) AND
            (P.Npersone <= p_persone_max or p_persone_max is null) AND
            (LOWER(replace(P.LuogoArrivo, ' ', '')) = (LOWER(replace(p_arrivo, ' ', ''))) OR p_arrivo is null) AND
            (P.Modificata = p_modificata or p_modificata is null) AND
            (P.Durata >= p_durata_min or p_durata_min is null) AND
            (P.Durata <= p_durata_max or p_durata_max is null) AND
            (((p_categoria='Standard' AND PrenS.FK_Prenotazione is not null) OR
              (p_categoria='Accessibile' AND PrenA.FK_Prenotazione is not null) OR
              (p_categoria='Lusso' AND PrenL.FK_Prenotazione is not null)
             ) OR p_categoria is null)
        )
        loop
            gui.AggiungiRigaTabella();
            gui.AggiungiElementoTabella('' || x.IDprenotazione || '');
            gui.AggiungiElementoTabella(x.LuogoPartenza || '');
            gui.AggiungiElementoTabella(to_char(x.DataOra, 'YYYY-MM-DD'));
            gui.AggiungiElementoTabella((to_char(x.DataOra, 'HH24:MI')));
            gui.AggiungiElementoTabella('' || x.LuogoArrivo || '');
            gui.AggiungiElementoTabella('' || x.Npersone || '');
            gui.AggiungiElementoTabella(case when x.Modificata=0 then 'no' else 'sì' end);
            gui.AggiungiElementoTabella('' || x.Durata || '');

        gui.AggiungiElementoTabella(case when x.PrenStd is not null then 'Standard'
                                                       when x.PrenLusso is not null then 'Lusso'
                                                       when x.PrenAcc is not null then 'Accessibile ' end );

        gui.AggiungiBottoneTabella('taxi liberi', url=>u_root||'.taxiCheSodd?p_idSess='||p_idSess|| chr(38)||'p_id_prenotazione='||x.IDprenotazione);

        gui.ChiudiRigaTabella();
        end loop;


        gui.ChiudiTabella(ident=>'1');
        gui.aCapo();
        gui.ChiudiPagina();

        EXCEPTION
            when NoPermessi then
                gui.ApriPagina('Errore!', p_idSess);
                gui.AggiungiPopup(false, 'Impossibile visualizzare questa pagina perchè l'||chr(39)||'utente non possiede i permessi corretti.');
                gui.ChiudiPagina();
            return;
            when others then
                gui.AggiungiPopup(false, 'Qualcosa è andato storto!');
                gui.ChiudiPagina();
            return;
    end visPrenPenFut;
----------------------------------------------------------------

--------------------------------visCorsePren---------------------------------------
    procedure visCorsePren (
        p_id_prenotazione CORSEPRENOTATE.FK_Prenotazione%TYPE default null,
        p_data_min varchar2 default null,
        p_data_max varchar2 default null,
        p_ora_min varchar2 default null,
        p_ora_max varchar2 default null,
        p_partenza in PRENOTAZIONI.LuogoPartenza%TYPE default null,
        p_arrivo in PRENOTAZIONI.LuogoArrivo%TYPE default null,
        p_durata_min CORSEPRENOTATE.Durata%TYPE default null,
        p_durata_max CORSEPRENOTATE.Durata%TYPE default null,
        p_importo_min CORSEPRENOTATE.Importo%TYPE default null,
        p_importo_max CORSEPRENOTATE.Importo%TYPE default null,
        p_passeggeri_min CORSEPRENOTATE.Passeggeri%TYPE default null,
        p_passeggeri_max CORSEPRENOTATE.Passeggeri%TYPE default null,
        p_km_min CORSEPRENOTATE.KM%TYPE default null,
        p_km_max CORSEPRENOTATE.KM%TYPE default null,
        p_taxi TAXI.IDtaxi%TYPE default null,
        p_categoria varchar2 default null,
        p_tipo varchar2 default null,
        p_id_autista AUTISTI.FK_Dipendente%TYPE default null,
        p_id_operatore OPERATORI.FK_Dipendente%TYPE default null,
        p_id_cliente CLIENTI.IDcliente%TYPE default null,
        p_msgVisCorsePren number default null,
        p_idSess in SESSIONIDIPENDENTI.IDSESSIONE%TYPE default null
    ) is
        head gui.StringArray;
        v_cliente CLIENTI.IDcliente%TYPE := null;
        v_autista AUTISTI.FK_Dipendente%TYPE := null;
        v_manager RESPONSABILI.FK_Dipendente%TYPE;
        v_isReferente number;
    begin

        --un autista può vedere solo le corse da lui effettuate
        --un cliente può vedere solo le corse da lui richieste
        --un manager può vedere tutte le corse e gli utenti coinvolti (cliente, operatori, autisti)
        gui.ApriPagina('Corse Prenotate', p_idSess);
        gui.aCapo(2);

        if SessionHandler.getRuolo(p_idSess) is null OR ((SessionHandler.checkRuolo(p_idSess,'Cliente')=false AND SessionHandler.checkRuolo(p_idSess,'Autista')=false AND SessionHandler.checkRuolo(p_idSess,'Manager')=false))
        then raise NoPermessi;
        end if;

        if p_msgVisCorsePren is not null then
            case p_msgVisCorsePren
            when 0 then gui.aggiungiPopUp(false, 'Errore durante la modifica della corsa.');
            when 1 then gui.aggiungiPopUp(true, 'La corsa è stata modificata correttamente.');
            end case;
        end if;

        if (SessionHandler.checkRuolo(p_idSess,'Cliente') OR SessionHandler.checkRuolo(p_idSess,'Autista'))
        then gui.AggiungiIntestazione('Corse prenotate eseguite da '||SessionHandler.getUsername(p_idSess), 'h1');
        else -- manager
            gui.AggiungiIntestazione('Corse prenotate', 'h1');
        end if;
        gui.aCapo(2);

        -- from per i filtri
        gui.ApriFormFiltro(u_root||'.visCorsePren');
        gui.AggiungiCampoFormFiltro('number', 'p_id_prenotazione', p_id_prenotazione, 'Prenotazione', minimo=>1);
        gui.AggiungiCampoFormFiltro('date', 'p_data_min', p_data_min, 'Data Min');
        gui.AggiungiCampoFormFiltro('date', 'p_data_max', p_data_max, 'Data Max');
        gui.AggiungiCampoFormFiltro('time', 'p_ora_min', p_ora_min, 'Ora Min');
        gui.AggiungiRigaTabella();

        gui.AggiungiCampoFormFiltro('time', 'p_ora_max', p_ora_max, 'Ora Max');
        gui.AggiungiCampoFormFiltro('text', 'p_partenza', p_partenza, 'Luogo di Partenza');
        gui.AggiungiCampoFormFiltro('text', 'p_arrivo', p_arrivo, 'Luogo di Arrivo');
        gui.AggiungiCampoFormFiltro('number', 'p_durata_min', p_durata_min, 'Durata Min');
        gui.AggiungiRigaTabella();

        gui.AggiungiCampoFormFiltro('number', 'p_durata_max', p_durata_max, 'Durata Max');
        gui.AggiungiCampoFormFiltro('number', 'p_importo_min', p_importo_min, 'Importo Min', minimo=>1);
        gui.AggiungiCampoFormFiltro('number', 'p_importo_max', p_importo_max, 'Importo Max', minimo=>1);
        gui.AggiungiCampoFormFiltro('number', 'p_passeggeri_min', p_passeggeri_min, 'Passeggeri Min', minimo=>1, massimo=>8);
        gui.AggiungiRigaTabella();

        gui.AggiungiCampoFormFiltro('number', 'p_passeggeri_max', p_passeggeri_max, 'Passeggeri Max', minimo=>1, massimo=>8);
        gui.AggiungiCampoFormFiltro('number', 'p_km_min', p_km_min, 'Chilometri percorsi Min', minimo=>1);
        gui.AggiungiCampoFormFiltro('number', 'p_km_max', p_km_max, 'Chilometri percorsi Max', minimo=>1);
        gui.AggiungiCampoFormFiltro('number', 'p_taxi', p_taxi, 'Taxi');
        gui.AggiungiRigaTabella();

        gui.ApriSelectFormFiltro('p_categoria', 'Categoria');
        gui.AggiungiOpzioneSelect('Standard', case p_categoria when 'Standard' then true else false end, 'Standard');
        gui.AggiungiOpzioneSelect('Accessibile', case p_categoria when 'Accessibile' then true else false end, 'Accessibile');
        gui.AggiungiOpzioneSelect('Lusso', case p_categoria when 'Lusso' then true else false end, 'Lusso');
        gui.ChiudiSelectFormFiltro;

        if SessionHandler.checkRuolo(p_idSess,'Manager')=true
        then
            gui.ApriSelectFormFiltro('p_tipo', 'Tipo');
            gui.AggiungiOpzioneSelect('Online', case p_tipo when 'Online' then true else false end, 'Online');
            gui.AggiungiOpzioneSelect('Telefonica', case p_tipo when 'Telefonica' then true else false end, 'Telefonica');
            gui.AggiungiOpzioneSelect('Anonima', case p_tipo when 'Anonima' then true else false end, 'Anonima');
            gui.ChiudiSelectFormFiltro;

            gui.AggiungiCampoFormFiltro('number', 'p_id_autista', p_id_autista, 'Autista', minimo=>1);
            gui.AggiungiCampoFormFiltro('number', 'p_id_operatore', p_id_operatore, 'Operatore', minimo=>1);
            gui.AggiungiRigaTabella();

            gui.AggiungiCampoFormFiltro('number', 'p_id_cliente', p_id_cliente, 'Cliente', minimo=>1);
        end if;

        gui.AggiungiCampoFormHidden('text', 'p_idSess', p_idSess);

        gui.AggiungiCampoFormFiltro('submit', '', '', 'Filtra');
        gui.chiudiFormFiltro();

        gui.ApriFormFiltro(u_root||'.visCorsePren');
        gui.AggiungiCampoFormHidden('text', 'p_idSess', p_idSess);
        gui.AggiungiCampoFormFiltro('submit', '', '', 'Reset filtro');
        gui.ChiudiFormFiltro();

        gui.aCapo();

        case
        when SessionHandler.getRuolo(p_idSess)='Cliente'
            then v_cliente:=SessionHandler.getIDuser(p_idSess);
        when SessionHandler.getRuolo(p_idSess)='Autista'
            then
                v_autista:=SessionHandler.getIDuser(p_idSess);
                --controllo se l'autista è un referente
                select count(*)
                into v_isReferente
                from taxi
                where fk_referente=v_autista;

                if v_isReferente>0
                then
                    gui.indirizzo(u_root||'.visCorseTaxiRiferiti?p_idSess='||p_idSess);
                    gui.BottonePrimario('Visualizza corse taxi riferiti');
                    gui.chiudiIndirizzo();
                    gui.aCapo();
                end if;
        when SessionHandler.getRuolo(p_idSess)='Manager'
            then v_manager:=SessionHandler.getIDuser(p_idSess);
        end case;

        case
        when v_cliente is not null then
            head := gui.StringArray('Prenotazione', 'Data', 'Ora', 'Partenza', 'Arrivo', 'Durata', 'Importo','Passeggeri','Chilometri percorsi', 'Taxi', 'Categoria');
        when v_autista is not null then
            head := gui.StringArray('Prenotazione', 'Data', 'Ora', 'Partenza', 'Arrivo', 'Durata', 'Importo','Passeggeri','Chilometri percorsi', 'Taxi', 'Categoria', 'Modifica');
        when v_manager is not null then
            head := gui.StringArray('Prenotazione', 'Data', 'Ora', 'Partenza', 'Arrivo', 'Durata', 'Importo','Passeggeri','Chilometri percorsi', 'Taxi', 'Categoria', 'Tipo', 'Autista', 'Operatore', 'Cliente');
        end case;

        gui.ApriTabella(head, ident=>'1');


        for x in (
            select C.*, P.LuogoPartenza, P.LuogoArrivo, Tu.FK_Taxi, Tu.FK_Autista, Tu.DataOraFine,
                        O.FK_Dipendente, Cl.IDcliente, NA.Tipo, PrenS.FK_Prenotazione as PrenStd,
                        PrenA.FK_Prenotazione as PrenAcc, PrenL.FK_Prenotazione as PrenLusso
            from Taxi Ta, Turni Tu, Prenotazioni P, CorsePrenotate C
            left join AnonimeTelefoniche A on A.FK_Prenotazione = C.FK_Prenotazione
            left join NonAnonime NA on NA.FK_Prenotazione = C.FK_Prenotazione
            left join PrenotazioneStandard PrenS on C.FK_Prenotazione=PrenS.FK_Prenotazione
            left join PrenotazioneAccessibile PrenA on C.FK_Prenotazione=PrenA.FK_Prenotazione
            left join PrenotazioneLusso PrenL on C.FK_Prenotazione=PrenL.FK_Prenotazione
            left join Clienti Cl on NA.FK_Cliente = Cl.IDcliente
            left join Operatori O on O.FK_Dipendente = NA.FK_Operatore or O.FK_Dipendente = A.FK_Operatore
            where
            C.FK_Prenotazione=P.IDprenotazione AND
            (PrenS.FK_Taxi = Ta.IDtaxi OR PrenA.FK_TaxiAccessibile = Ta.IDtaxi OR PrenL.FK_Taxi = Ta.IDtaxi) AND
            Tu.FK_Taxi = Ta.IDtaxi AND
            C.DataOra >= Tu.DataOraInizioEff AND
            C.DataOra <= Tu.DataOraFineEff AND
            ((v_cliente is not null and NA.FK_Cliente=v_cliente) or
            (v_autista is not null and Tu.FK_Autista=v_autista) or
            (v_manager is not null))
            AND --condizioni per i filtri
            (C.FK_Prenotazione = p_id_prenotazione OR p_id_prenotazione is null) AND
            ((trunc(C.DataOra) >= to_date(p_data_min, 'YYYY-MM-DD')) or p_data_min is null) AND
            ((trunc(C.DataOra) <= to_date(p_data_max, 'YYYY-MM-DD')) or p_data_max is null) AND
            (to_char(C.DataOra, 'HH24:MI') >= p_ora_min or p_ora_min is null) AND
            (to_char(C.DataOra, 'HH24:MI') <= p_ora_max or p_ora_max is null) AND
            (C.Durata >= p_durata_min OR p_durata_min is null) AND
            (C.Durata <= p_durata_max OR p_durata_max is null) AND
            (C.Importo >= p_importo_min OR p_importo_min is null) AND
            (C.Importo <= p_importo_max OR p_importo_max is null) AND
            (C.Passeggeri >= p_passeggeri_min OR p_passeggeri_min is null) AND
            (C.Passeggeri <= p_passeggeri_max OR p_passeggeri_max is null) AND
            (C.KM >= p_km_min OR p_km_min is null) AND
            (C.KM >= p_km_max OR p_km_max is null) AND
            (Tu.FK_Taxi = p_taxi OR p_taxi is null) AND
            ((v_manager is not null and (Tu.FK_Autista = p_id_autista OR p_id_autista is null)) or (v_manager is null)) AND -- solo il manager può filtrare usando questi parametri
            ((v_manager is not null and (O.FK_Dipendente = p_id_operatore OR p_id_operatore is null)) or (v_manager is null)) AND
            ((v_manager is not null and (Cl.IDcliente = p_id_cliente OR p_id_cliente is null)) or (v_manager is null)) AND
            (((p_tipo='Online' AND NA.Tipo=0) OR (p_tipo='Telefonica' AND NA.Tipo=1) OR (p_tipo='Anonima' AND NA.Tipo is null)) OR p_tipo is null) AND --funziona solo perchè ce n'è solo uno non nullo
            (((p_categoria='Standard' AND PrenS.FK_Prenotazione is not null) OR
            (p_categoria='Accessibile' AND PrenA.FK_Prenotazione is not null) OR
            (p_categoria='Lusso' AND PrenL.FK_Prenotazione is not null)
            ) OR p_categoria is null)
        )
        loop
            gui.AggiungiRigaTabella();
            if v_autista is not null
            then gui.AggiungiElementoTabella('' || x.FK_Prenotazione || '');
            else --solo clienti e manager possono visualizzare le prenotazioni
                gui.AggiungiBottoneTabella('' || x.FK_Prenotazione || '', url=> u_root||'.visPren?p_idSess='||p_idSess||chr(38)||'p_id='||x.FK_Prenotazione);
            end if;

            gui.AggiungiElementoTabella('' || x.DataOra || '');
            gui.AggiungiElementoTabella((to_char(x.DataOra, 'HH24:MI')));
            gui.AggiungiElementoTabella('' || x.LuogoPartenza || '');
            gui.AggiungiElementoTabella('' || x.LuogoArrivo || '');
            gui.AggiungiElementoTabella('' || x.Durata || '');
            gui.AggiungiElementoTabella('' || x.Importo || ''||'€');
            gui.AggiungiElementoTabella('' || x.Passeggeri || '');
            gui.AggiungiElementoTabella('' || x.KM || ''||'km');

            if v_cliente is not null
            then gui.AggiungiElementoTabella('' || x.FK_Taxi || '');
            else gui.AggiungiBottoneTabella(x.FK_Taxi, url=>u_user||'.gruppo2.visualizzaUnTaxi?id_ses='||p_idSess|| chr(38)||'t_IDTaxi='||x.FK_Taxi);
            end if;

            gui.AggiungiElementoTabella(case when x.PrenStd is not null then 'Standard'
                                                        when x.PrenLusso is not null then 'Lusso'
                                                        when x.PrenAcc is not null then 'Accessibile ' end );

            -- un autista può modificare le corse da lui effettuate entro 30 minuti dalla fine del turno in cui sono state eseguite
            if v_autista is not null and sysdate < x.DataOraFine + interval '30' minute
            then
                gui.ApriElementoPulsanti();
                gui.AggiungiPulsanteModifica(u_root||'.modificaCorsaPrenotata?id_ses='||p_idSess||chr(38)||'p_id='||x.FK_Prenotazione||chr(38)||'p_url='||u_root||'.visCorsePren?p_idSess='||p_idSess);
                gui.ChiudiElementoPulsanti();
            end if;

            if v_manager is not null
            then
                gui.AggiungiElementoTabella(case when x.Tipo=0 then 'Online'
                                                            when x.Tipo=1 then 'Telefonica'
                                                            when x.Tipo is null then 'Anonima' end);

                gui.AggiungiBottoneTabella(x.FK_Autista, url=>u_user||'.Gruppo4.visualizzaDipendente?idSessione='||p_idSess|| chr(38)||'imatricola='||x.FK_Autista);

                if x.FK_Dipendente is null
                then gui.AggiungiElementoTabella('—');
                else gui.AggiungiBottoneTabella(x.FK_Dipendente, url=>u_user||'.Gruppo4.visualizzaDipendente?idSessione='||p_idSess|| chr(38)||'imatricola='||x.FK_Dipendente);
                end if;

                if x.IDcliente is null
                then gui.AggiungiElementoTabella('—');
                else gui.AggiungiBottoneTabella(x.IDcliente, url=>u_user||'.Gruppo3.visualizzaProfilo?idSess='||p_idSess|| chr(38)||'id='||x.IDcliente);
                end if;

            end if;

            gui.ChiudiRigaTabella();
        end loop;

        gui.ChiudiTabella(ident=>'1');
        gui.aCapo();
        gui.ChiudiPagina();

        EXCEPTION
            when NoPermessi then
                gui.ApriPagina('Errore!', p_idSess);
                gui.AggiungiPopup(false, 'Impossibile visualizzare questa pagina perchè l'||chr(39)||'utente non possiede i permessi corretti.');
                gui.ChiudiPagina();
            return;
            when others then
                gui.AggiungiPopup(false, 'Qualcosa è andato storto!');
                gui.ChiudiPagina();
            return;

    end visCorsePren;

-----------------------------------------------------------------------
-----------------------------------TaxiCheSodd----------------------------------------------
    procedure taxiCheSodd (
        p_id_prenotazione in PRENOTAZIONI.IDprenotazione%TYPE default null,
        p_dataora varchar2 default null,
        p_partenza in PRENOTAZIONI.LuogoPartenza%TYPE default null,
        p_persone in PRENOTAZIONI.Npersone%TYPE default null,
        p_arrivo in PRENOTAZIONI.LuogoArrivo%TYPE default null,
        p_disabili in PRENOTAZIONEACCESSIBILE.NpersoneDisabili%TYPE default null,
        p_optionals varchar2 default null,
        p_idCliente in CLIENTI.IDcliente%TYPE default null,
        p_telefono in ANONIMETELEFONICHE.Ntelefono%TYPE default null,
        p_id_taxi in TAXI.IDtaxi%TYPE default null,
        p_msgTaxiCheSodd number default null,
        p_idSess in SESSIONIDIPENDENTI.IDSESSIONE%TYPE default null
    ) is
        head gui.StringArray;
        v_link varchar2(300);
        v_finePrenotazione date :=null;
        v_prenInfo r_PrenCategoria;
        v_arrayIdOptionals gui.StringArray;
        v_arrayNomeOptionals gui.StringArray;
        v_esiste TAXI.IDtaxi%TYPE;
        v_nTaxi number;
        v_taxiSoddisfa number;

    begin

        gui.ApriPagina('Taxi che possono soddisfare una prenotazione', p_idSess);
        gui.aCapo(2);
        gui.AggiungiIntestazione('Taxi che possono soddisfare la prenotazione '|| p_id_prenotazione, 'h1');
        gui.aCapo(2);

        if SessionHandler.getRuolo(p_idSess) is null OR SessionHandler.getRuolo(p_idSess) <> 'Operatore'
        then raise NoPermessi;
        end if;

        if p_msgTaxiCheSodd is not null
        then case  p_msgTaxiCheSodd
            when 1 then gui.AggiungiPopup(false, 'Impossibile assegnare il taxi taxi perchè il taxi non può soddisfare la prenotazione.');
            when 2 then gui.AggiungiPopup(false, 'Il taxi selezionato non esiste.');
            end case;
        end if;

        -- la procedura viene chiamata o solo con id prenotazione (ad esempio, da un visualizza prenotazione)
        -- o solo con i dati di una prenotazione (per l'inserimento di una prenotazione telefonica da parte di un operatore)
        if (p_id_prenotazione is null and (p_dataora is null OR p_partenza is null OR p_persone is null OR p_arrivo is null OR (p_idCliente is null and p_telefono is null) or (p_idCliente is not null and p_telefono is not null))) OR
             (p_id_prenotazione is not null and (p_dataora is not null OR p_partenza is not null OR p_persone is not null OR p_arrivo is not null OR p_idCliente is not null or p_telefono is not null))
        then raise PrenIdDati;
        end if;

        if p_id_taxi is null then

            -- se la procedura viene chiamata con un id prenotazione, prendo i dati ad essa associati
            if p_id_prenotazione is not null
            then
                begin
                select *
                into v_prenInfo
                from Prenotazioni P
                left join PrenotazioneStandard PrenS on P.IDprenotazione=PrenS.FK_Prenotazione
                left join PrenotazioneAccessibile PrenA on P.IDprenotazione=PrenA.FK_Prenotazione
                left join PrenotazioneLusso PrenL on P.IDprenotazione=PrenL.FK_Prenotazione
                where P.IDprenotazione=p_id_prenotazione;
                EXCEPTION
                when NO_DATA_FOUND
                then raise PrenNonEsiste;
                when others then raise;
                end;

                v_finePrenotazione:=v_prenInfo.r_dataOra + NUMTODSINTERVAL (v_prenInfo.r_durata, 'MINUTE');

                if (v_prenInfo.r_stato = 'annullata') OR (v_prenInfo.r_stato = 'rifiutata') then raise PrenAnnRif; end if;

                --se la prenotazione è di lusso, prendo tutti gli optional richiesti
                if v_prenInfo.r_prenLss is not null
                then
                    v_arrayIdOptionals:=gui.StringArray();
                    v_arrayNomeOptionals:=gui.StringArray();
                    for x in (
                        select o.IDoptionals, o.Nome
                        from RichiestePrenLusso rpl
                        join Optionals o on o.IDoptionals=rpl.Fk_optionals
                        where rpl.FK_prenotazione=v_prenInfo.r_IDprenotazione
                    ) loop
                        v_arrayIdOptionals.extend();
                        v_arrayIdOptionals(v_arrayIdOptionals.count):=x.IDoptionals;
                        v_arrayNomeOptionals.extend();
                        v_arrayNomeOptionals(v_arrayNomeOptionals.count):=x.Nome;
                    end loop;
                end if;

            else -- se la proceduta è chiamata passando i dati di una prenotazione, le variabili prendono i valori passati per parametro
                v_prenInfo.r_dataOra:=to_date(to_char(to_date(p_dataora,'YYYY-MM-DD"T"HH24:MI'), 'YYYY-MM-DD HH24:MI'), 'YYYY-MM-DD HH24:MI');
                v_prenInfo.r_durata:=FLOOR(DBMS_RANDOM.VALUE(10, 30)); v_prenInfo.r_luogoPartenza:=p_partenza;
                v_finePrenotazione:= v_prenInfo.r_dataOra + NUMTODSINTERVAL (v_prenInfo.r_durata, 'MINUTE');
                v_prenInfo.r_luogoArrivo:=p_arrivo; v_prenInfo.r_nPersone:=p_persone; v_prenInfo.r_stato:='—';

                --controlli sui parametri
                if p_disabili is not null and p_optionals is not null then raise ErroreParametri; end if;
                if p_persone<1 or p_persone>8 then raise ErroreParametri; end if;

                case
                when p_disabili is not null
                    then
                        if (p_disabili<1 or p_disabili>2) or p_persone>3 then raise ErroreParametri; end if;
                        v_prenInfo.r_PrenAcc:=0; --valore simbolico, che rende la variabile not null per poter identificare più facilmente la categoria
                        v_prenInfo.r_NperDis:=p_disabili;
                when p_optionals is not null
                    then v_prenInfo.r_PrenLss:=0; --valore simbolico, che rende la variabile not null per poter identificare più facilmente la categoria
                        v_arrayIdOptionals:=gui.StringArray();
                        v_arrayNomeOptionals:=gui.StringArray();
                        if substr(p_optionals, 1,2)<>'-1' --la pren di lusso richiede degli optional
                        then v_arrayIdOptionals:=utility.StringToArray(p_optionals);
                            for i in 1..v_arrayIdOptionals.count loop
                                v_arrayNomeOptionals.extend();
                                select Nome into v_arrayNomeOptionals(v_arrayNomeOptionals.count) from optionals where IDoptionals=v_arrayIdOptionals(i);
                            end loop;
                        end if;
                else
                    v_prenInfo.r_PrenStd:=0;
                end case;

        end if;


            if v_prenInfo.r_dataOra <= SYSDATE then raise PrenPassata; end if;

            case
                when v_prenInfo.r_prenStd is not null then head:= gui.StringArray('ID prenotazione', 'Data', 'Orario di partenza', 'Luogo di partenza', 'Orario previsto di arrivo', 'Luogo di arrivo', 'Numero di persone', 'Stato', 'Categoria', 'ID taxi');
                when v_prenInfo.r_prenAcc is not null then head:= gui.StringArray('ID prenotazione', 'Data', 'Orario di partenza', 'Luogo di partenza', 'Orario previsto di arrivo', 'Luogo di arrivo', 'Numero di persone', 'Stato', 'Categoria', 'Numero di persone disabili', 'ID taxi');
                when v_prenInfo.r_prenLss is not null then head:= gui.StringArray('ID prenotazione', 'Data', 'Orario di partenza', 'Luogo di partenza', 'Orario previsto di arrivo', 'Luogo di arrivo', 'Numero di persone', 'Stato', 'Categoria', 'Optionals richiesti', 'ID taxi');
            end case;

            -- tabella di riepilogo prenotazione
            gui.ApriTabella(head);
            gui.AggiungiRigaTabella();
            if p_id_prenotazione is not null then gui.AggiungiElementoTabella(p_id_prenotazione);
                else gui.AggiungiElementoTabella('—');
            end if;
            gui.AggiungiElementoTabella(to_char(v_prenInfo.r_dataOra, 'YYYY-MM-DD'));
            gui.AggiungiElementoTabella(to_char(v_prenInfo.r_dataOra, 'HH24:MI'));
            gui.AggiungiElementoTabella('' || v_prenInfo.r_luogoPartenza || '');
            gui.AggiungiElementoTabella(to_char(v_finePrenotazione, 'HH24:MI'));
            gui.AggiungiElementoTabella('' || v_prenInfo.r_luogoArrivo || '');
            gui.AggiungiElementoTabella('' || v_prenInfo.r_nPersone || '');
            gui.AggiungiElementoTabella('' || v_prenInfo.r_stato || '');
            gui.AggiungiElementoTabella( case
                when v_prenInfo.r_prenStd is not null then 'Standard'
                when v_prenInfo.r_prenAcc is not null then 'Accessibile'
                when v_prenInfo.r_prenLss is not null then 'Lusso'
                end
            );

            if v_prenInfo.r_prenAcc is not null then gui.AggiungiElementoTabella('' || v_prenInfo.r_NperDis || ''); end if;
            if v_prenInfo.r_prenLss is not null then
                if v_arrayNomeOptionals.count>0 then utility.DropdownInformation(v_arrayNomeOptionals,'optionals');
                else gui.AggiungiElementoTabella('—');
                end if;
            end if;

            gui.AggiungiElementoTabella( case
                when v_prenInfo.r_taxiStd is not null then '' || v_prenInfo.r_taxiStd || ''
                when v_prenInfo.r_taxiAcc is not null then '' || v_prenInfo.r_taxiAcc || ''
                when v_prenInfo.r_taxiLss is not null then '' || v_prenInfo.r_taxiLss || ''
                else '—'
                end
            );

            gui.ChiudiRigaTabella();
            gui.ChiudiTabella();

            gui.aCapo();
            head:=gui.StringArray('ID Taxi', 'Tariffa', ' ', ' ');
            gui.ApriTabella(head);

            v_nTaxi:=0; -- variabile per controllare che ci sia almeno un taxi libero per la prenotazione
            for x in (
                -- prendo i taxi che hanno un turno in quell'ora e con il giusto numero di posti
                select Ta.IDtaxi, Ta.Tariffa
                from Turni Tu, Taxi Ta
                left join TaxiStandard TaS on Ta.IDtaxi=TaS.FK_taxi
                left join TaxiAccessibile TaA on Ta.IDtaxi=TaA.FK_taxi
                left join TaxiLusso TaL on Ta.IDtaxi=TaL.FK_taxi
                where
                Tu.FK_Taxi=Ta.IDtaxi AND
                v_prenInfo.r_dataOra >= Tu.DataOraInizio AND
                v_finePrenotazione <= Tu.DataOraFine AND
                Ta.Nposti>= v_prenInfo.r_nPersone AND (
                    (v_prenInfo.r_PrenStd is not null AND TaS.FK_Taxi is not null) OR
                    (v_prenInfo.r_PrenAcc is not null AND TaA.FK_Taxi is not null AND TaA.NpersoneDisabili>=v_prenInfo.r_NperDis) OR
                    (v_prenInfo.r_PrenLss is not null AND TaL.FK_Taxi is not null)
                )
            )
            loop
                if v_prenInfo.r_prenLss is not null and not(utility.taxiPossiedeOptionals(x.IDtaxi, v_arrayIdOptionals))
                then continue;
                end if;

                if utility.checkNotPrenotazioniSovrapposte(v_prenInfo.r_dataOra, v_finePrenotazione, x.IDtaxi)
                --ritorna true se non ci sono prenotazioni sovrapposte associate a quel taxi nel periodo tra inizio e fine prevista della prenotazione
                then
                    v_nTaxi:=v_nTaxi+1;
                    gui.AggiungiRigaTabella();
                    gui.AggiungiElementoTabella('' || x.IDtaxi || '');
                    gui.AggiungiElementoTabella(to_char(x.Tariffa, '0.00')|| ' eur/min');

                if p_id_prenotazione is not null
                then
                    -- la prenotazione è già nel database, bisogna solo assegnare il taxi
                    v_link:=u_root||'.taxiCheSodd?p_idSess='||p_idSess||chr(38)||'p_id_prenotazione='||p_id_prenotazione||chr(38)||'p_id_taxi='||x.IDtaxi;
                    gui.apriElementoPulsanti();
                    gui.AggiungiPulsanteGenerale(''''||v_link||'''', 'Assegna taxi');
                    gui.chiudiElementoPulsanti();
                else
                    -- l'operatore vuole inserire una prenotazione telefonica accettata
                    v_link:=u_root||'.insPren?p_idSess='||p_idSess||chr(38)||'p_id_taxi='||x.IDtaxi||chr(38)||
                    'p_dataora='||p_dataora||chr(38)||'p_partenza='||v_prenInfo.r_luogoPartenza||chr(38)||'p_persone='||v_prenInfo.r_nPersone||chr(38)||'p_arrivo='||v_prenInfo.r_luogoArrivo
                    ||chr(38)||'p_durata='||v_prenInfo.r_durata||chr(38)||'p_disabili='||v_prenInfo.r_NperDis||chr(38)||'p_optionals='||p_optionals||chr(38)||'p_idCliente='||p_idCliente
                    ||chr(38)||'p_telefono='||p_telefono||chr(38)||'p_stato=accettata'||chr(38)||case when p_telefono is null then 'p_insConvBoolean=1' END|| case when p_telefono is not null then 'p_insConvBoolean=0' end;
                    gui.apriElementoPulsanti();
                    gui.AggiungiPulsanteGenerale(''''||v_link||'''', 'Inserisci prenotazione e assegna taxi');
                    gui.chiudiElementoPulsanti();
                end if;

                -- l'operatore può decidere quale taxi assegnare anche dopo aver visualizzato la prenotazioni associate ai taxi liberi
                gui.AggiungiBottoneTabella('visualizza prenotazioni taxi', url=>u_root||'.visualizzaPrenotazioniTaxi?p_idSess='||p_idSess|| chr(38)||'p_id_taxi='||x.IDtaxi);

            gui.ChiudiRigaTabella();
            end if;

            end loop;

                -- se non ci sono taxi liberi
                if v_nTaxi=0 then
                    gui.AggiungiIntestazione('Non ci sono taxi che possono soddisfare la prenotazione.', 'h3');
                    if p_id_prenotazione is null
                        then -- l'operatore inserisce una prenotazione telefonica rifiutata
                        gui.BottoneAggiungi('Inserisci prenotazione rifiutata', url=>u_root||'.insPren?p_idSess='||p_idSess||chr(38)||
                        'p_dataora='||p_dataora||chr(38)||'p_partenza='||v_prenInfo.r_luogoPartenza||chr(38)||'p_persone='||v_prenInfo.r_nPersone||chr(38)||'p_arrivo='||v_prenInfo.r_luogoArrivo
                        ||chr(38)||'p_durata='||v_prenInfo.r_durata||chr(38)||'p_disabili='||v_prenInfo.r_NperDis||chr(38)||'p_optionals='||p_optionals||chr(38)||'p_idCliente='||p_idCliente||chr(38)||'p_telefono='||p_telefono
                        ||chr(38)||'p_stato=rifiutata'||chr(38)||'p_insConvBoolean=0');
                    end if;
                end if;

        gui.ChiudiTabella();

        else -- se p_id_taxi non è null, viene assegnato il taxi

            -- si assegna un taxi solo se viene dato l'id di una prenotazione, se ci sono altri parametri vengono ignorati
            if p_id_prenotazione is null then raise PrenIdDati; end if;

            begin
            select IDtaxi into v_esiste from Taxi where IDtaxi=p_id_taxi;
            EXCEPTION
            when NO_DATA_FOUND then raise TaxiNonEsiste;
            when others then raise;
            end;

            begin
            select *
            into v_prenInfo
            from Prenotazioni P
            left join PrenotazioneStandard PrenS on P.IDprenotazione=PrenS.FK_Prenotazione
            left join PrenotazioneAccessibile PrenA on P.IDprenotazione=PrenA.FK_Prenotazione
            left join PrenotazioneLusso PrenL on P.IDprenotazione=PrenL.FK_Prenotazione
            where P.IDprenotazione=p_id_prenotazione;
            EXCEPTION
            when NO_DATA_FOUND
            then raise PrenNonEsiste;
            when others then raise;
            end;

            v_finePrenotazione:=v_prenInfo.r_dataOra + NUMTODSINTERVAL (v_prenInfo.r_durata, 'MINUTE');

            if (v_prenInfo.r_stato = 'annullata') OR (v_prenInfo.r_stato = 'rifiutata') then raise PrenAnnRif; end if;

            -- v_taxiSoddisfa sarà 1 se il taxi possiede ancora i requisiti adatti per la prenotazione
            select count(*)
            into v_taxiSoddisfa
            from Turni Tu, Taxi Ta
            left join TaxiStandard TaS on Ta.IDtaxi=TaS.FK_taxi
            left join TaxiAccessibile TaA on Ta.IDtaxi=TaA.FK_taxi
            left join TaxiLusso TaL on Ta.IDtaxi=TaL.FK_taxi
            where
            Ta.IDtaxi=p_id_taxi AND
            Tu.FK_Taxi=Ta.IDtaxi AND
            v_prenInfo.r_dataOra >= Tu.DataOraInizio AND
            v_finePrenotazione <= Tu.DataOraFine AND
            Ta.Nposti>= v_prenInfo.r_nPersone AND (
                (v_prenInfo.r_PrenStd is not null AND TaS.FK_Taxi is not null) OR
                (v_prenInfo.r_PrenAcc is not null AND TaA.FK_Taxi is not null AND TaA.NpersoneDisabili>=v_prenInfo.r_NperDis) OR
                (v_prenInfo.r_PrenLss is not null AND TaL.FK_Taxi is not null)
            );

            if v_prenInfo.r_prenLss is not null
            then
                v_arrayIdOptionals:=gui.StringArray();
                for x in (
                    select FK_optionals
                    from richiestePrenLusso where FK_prenotazione=v_prenInfo.r_IDprenotazione
                ) loop
                    v_arrayIdOptionals.extend();
                    v_arrayIdOptionals(v_arrayIdOptionals.count):=x.FK_optionals;
                end loop;

                --controllo se il taxi possiede tutti gli optional richiesti
                if not(utility.taxiPossiedeOptionals(p_id_taxi, v_arrayIdOptionals))
                    then v_taxiSoddisfa:=0;
                end if;
            end if;

        -- controllo che non ci siano prenotazioni sovrapposte
        if not (utility.checkNotPrenotazioniSovrapposte(v_prenInfo.r_dataOra, v_finePrenotazione, p_id_taxi))
            then v_taxiSoddisfa:=0;
        end if;

            if v_taxiSoddisfa=0 then raise TaxiNonAssegnabile; end if;

            savepoint savepointAssegna;

            update PrenotazioneStandard
            set FK_Taxi=p_id_taxi
            where FK_Prenotazione=v_prenInfo.r_IDprenotazione;

            update PrenotazioneAccessibile
            set FK_TaxiAccessibile=p_id_taxi
            where FK_Prenotazione=v_prenInfo.r_IDprenotazione;

            update PrenotazioneLusso
            set FK_Taxi=p_id_taxi
            where FK_Prenotazione=v_prenInfo.r_IDprenotazione;

            update Prenotazioni set Stato='accettata' where IDprenotazione=v_prenInfo.r_IDprenotazione;

            commit;

            gui.reindirizza(u_root||'.visPren?p_idSess='||p_idSess||chr(38)||'p_id='||p_id_prenotazione||chr(38)||'p_visPrenBoolean=7');

            end if;

        gui.aCapo();
        gui.ChiudiPagina();

        EXCEPTION
            when PrenIdDati then
                gui.AggiungiPopup(false, 'I dati inseriti della prenotazione sono errati.');
                gui.ChiudiPagina();
            return;
            when PrenNonEsiste then
                gui.AggiungiPopup(false, 'La prenotazione non esiste.');
                gui.ChiudiPagina();
            return;
            when PrenPassata then
                if p_id_prenotazione is not null then gui.reindirizza(u_root||'.visPren?p_idSess='||p_idSess||chr(38)||'p_id='||p_id_prenotazione||chr(38)||'p_visPrenBoolean=9');
                else gui.reindirizza(u_root||'.insPren?p_idSess='||p_idSess||chr(38)||'p_visPrenBoolean=5');
                end if;
            return;
            when PrenAnnRif then
                gui.reindirizza(u_root||'.visPren?p_idSess='||p_idSess||chr(38)||'p_id='||p_id_prenotazione||chr(38)||'p_visPrenBoolean=8');
            return;
            when NoPermessi then
                gui.AggiungiPopup(false, 'Impossibile visualizzare questa pagina perchè l'||chr(39)||'utente non possiede i permessi corretti.');
                gui.ChiudiPagina();
            return;
            when ErroreParametri then
                gui.reindirizza(u_root||'.insPren?p_idSess='||p_idSess||chr(38)||'p_visPrenBoolean=4');
            return;
            when TaxiNonEsiste then
                gui.reindirizza(u_root||'.taxiCheSodd?p_idSess='||p_idSess||chr(38)||'p_id_prenotazione='||p_id_prenotazione||chr(38)||'p_msgTaxiCheSodd=2');
            return;
            when TaxiNonAssegnabile then
                gui.reindirizza(u_root||'.taxiCheSodd?p_idSess='||p_idSess||chr(38)||'p_id_prenotazione='||p_id_prenotazione||chr(38)||'p_msgTaxiCheSodd=1');
            when others then
                rollback to savepointAssegna;
                gui.AggiungiPopup(false, 'Qualcosa è andato storto!');
                gui.ChiudiPagina();
            return;
    end taxiCheSodd;
---------------------------------------------------------------------------------------------

-----------------------statistica---------------------------------
    procedure statCorsePNP (
        p_idSess in SESSIONIDIPENDENTI.IDSESSIONE%TYPE default null,
        p_dataInizio varchar2 default null,
        p_dataFine varchar2 default null
    )
    is
    v_nCorsePrenotateTotali number;
    v_nCorseNonPrenotateTotali number;
    v_ncorseTotali number;
    head gui.StringArray;

    v_labels varchar2(300);
    v_dataPren varchar2(300);
    v_dataNonPren varchar2(300);

    begin

        gui.ApriPagina('Statistiche su corse effettuate con taxi standard', p_idSess);
        gui.aCapo(2);
        gui.AggiungiIntestazione('Statistiche su corse effettuate con taxi standard', 'h1');
        gui.aCapo(2);

        if SessionHandler.getRuolo(p_idSess) is null OR SessionHandler.getRuolo(p_idSess) <> 'Manager'
        then raise NoPermessi;
        end if;

        if p_dataInizio is null AND p_dataFine is null
        then
            gui.AggiungiForm(url=>u_root||'.statCorsePNP');
            gui.AggiungiGruppoInput();
            gui.AggiungiLabel('DOI', 'Data di inizio');
            gui.AggiungiCampoForm('date', nome=>'p_dataInizio', ident=>'DOI', required=>false, placeholder=> 'Data e ora di inizio', massimo=>to_char(sysdate, 'YYYY-MM-DD'));
            gui.AggiungiLabel('DOF', 'Data di fine');
            gui.AggiungiCampoForm('date', nome=>'p_dataFine', ident=>'DOF', required=>false, placeholder=> 'Data e ora di fine', massimo=>to_char(sysdate, 'YYYY-MM-DD'));
            gui.AggiungiCampoFormHidden('text', 'p_idSess',p_idSess);
            gui.AggiungiBottoneSubmit('Calcola');
            gui.ChiudiGruppoInput();
            gui.ChiudiForm();

        else --visualizza statistiche

            head:=gui.StringArray('Giorno', 'Corse Totali', 'Numero corse prenotate', 'Percentuale corse prenotate', 'Numero corse non prenotate', 'Percentuale corse non prenotate');
            gui.ApriTabella(head);

            if p_dataInizio is not null AND p_dataFine is not null and to_date(p_dataInizio, 'YYYY-MM-DD')>to_date(p_dataFine, 'YYYY-MM-DD')
            then raise ErroreParametri;
            end if;

            v_nCorsePrenotateTotali:=0;
            v_nCorseNonPrenotateTotali:=0;

            for x in (
                select *
                from countCorsePNP
                where (p_dataInizio is null or to_date(giorno,'YYYY-MM-DD')>=to_date(p_dataInizio, 'YYYY-MM-DD')) AND
                     (p_dataFine is null or to_date(giorno,'YYYY-MM-DD')<=to_date(p_dataFine,'YYYY-MM-DD'))
                order by giorno
            ) loop
            gui.AggiungiRigaTabella();
            gui.AggiungiElementoTabella(x.giorno);

            if x.CorsePren is not null and x.CorseNonPren is not null
            then gui.AggiungiElementoTabella(x.CorsePren+x.CorseNonPren);
            elsif x.CorsePren is not null
                then
                gui.AggiungiElementoTabella(x.CorsePren);
            elsif x.CorseNonPren is not null
                then
                gui.AggiungiElementoTabella(x.CorseNonPren);
            end if;


            gui.AggiungiElementoTabella(case when x.CorsePren is not null then x.CorsePren else '0' end);

            if x.CorsePren is not null and x.CorseNonPren is not null
                then gui.AggiungiElementoTabella(to_char((x.CorsePren*100)/(x.CorsePren+x.CorseNonPren), 'fm99D00')||'%');
            elsif x.CorsePren is null
                then gui.AggiungiElementoTabella('0%');
            else
                gui.AggiungiElementoTabella('100%');
            end if;

            gui.AggiungiElementoTabella(case when x.CorseNonPren is not null then x.CorseNonPren else '0' end);

            if x.CorseNonPren is not null and x.CorsePren is not null
                then gui.AggiungiElementoTabella(to_char((x.CorseNonPren*100)/(x.CorsePren+x.CorseNonPren), 'fm99D00')||'%');
            elsif x.CorseNonPren is null
                then gui.AggiungiElementoTabella('0%');
            else
                gui.AggiungiElementoTabella('100%');
            end if;

            gui.ChiudiRigaTabella();

            v_labels:=v_labels||','||chr(39)||x.giorno||chr(39);
            v_dataPren:=v_dataPren||','|| '' || x.CorsePren || '';
            v_dataNonPren:=v_dataNonPren||','||''|| x.CorseNonPren || '';

            end loop;

            gui.ChiudiTabella();

            v_labels:=substr(v_labels,2); --tolgo il primo ,
            v_dataPren:=substr(v_dataPren,2);
            v_dataNonPren:=substr(v_dataNonPren,2);

            select sum(CorsePren), sum(CorseNonPren)
            into v_nCorsePrenotateTotali, v_nCorseNonPrenotateTotali
            from countCorsePNP
            where (p_dataInizio is null or to_date(giorno,'YYYY-MM-DD')>=to_date(p_dataInizio, 'YYYY-MM-DD')) AND
                     (p_dataFine is null or to_date(giorno,'YYYY-MM-DD')<=to_date(p_dataFine,'YYYY-MM-DD'));

            v_nCorseTotali:=v_nCorsePrenotateTotali+v_nCorseNonPrenotateTotali;

            gui.aCapo(2);
            head:=gui.StringArray('Dal', 'Al', 'Corse Totali', 'Corse prenotate totali', 'Percentuale corse prenotate totali', 'Corse non prenotate totali', 'Percentuale corse non prenotate totali');
            gui.ApriTabella(head);
            gui.AggiungiRigaTabella();
            gui.AggiungiElementoTabella(case when p_dataInizio is not null then p_dataInizio else '—' end);
            gui.AggiungiElementoTabella(case when p_dataFine is not null then p_dataFine else '—' end);
            gui.AggiungiElementoTabella(v_nCorseTotali);
            gui.AggiungiElementoTabella(v_nCorsePrenotateTotali);

            if v_nCorsePrenotateTotali=0
            then gui.AggiungiElementoTabella('0%');
            else gui.AggiungiElementoTabella(to_char(v_nCorsePrenotateTotali*100/v_nCorseTotali, 'fm99D00')||'%');
            end if;

            gui.AggiungiElementoTabella(v_nCorseNonPrenotateTotali);

            if v_nCorseNonPrenotateTotali=0
            then gui.AggiungiElementoTabella('0%');
            else gui.AggiungiElementoTabella(to_char(v_nCorseNonPrenotateTotali*100/v_nCorseTotali, 'fm99D00')||'%');
            end if;

            gui.ChiudiRigaTabella();
            gui.ChiudiTabella();

            gui.aCapo(2);

            gui.aggiungiChart('stats', '{
                                    type: '||chr(39)||'bar'||chr(39)||',
                                    data: {
                                    labels: ['||v_labels||'],
                                    datasets: [{
                                        label: '||chr(39)||'corse prenotate'||chr(39)||',
                                        data: ['||v_dataPren||'],
                                        borderWidth: 1
                                    },
                                    {
                                        label: '||chr(39)||'corse non prenotate'||chr(39)||',
                                        data: ['||v_dataNonPren||'],
                                        borderWidth: 1
                                    }]
                                    },
                                    options: {
                                    scales: {
                                        y: {
                                        beginAtZero: true
                                        }
                                    }
                                    }
                                }');

            gui.aCapo(2);

        end if;

        gui.ChiudiPagina();

        EXCEPTION
        when NoPermessi then
            gui.AggiungiPopup(false, 'Impossibile visualizzare questa pagina perchè l'||chr(39)||'utente non possiede i permessi corretti.');
            gui.ChiudiPagina();
        return;
        when ErroreParametri then
            gui.AggiungiPopup(false, 'Errore nell'||chr(39)||'inserimento dei parametri: la data di inizio deve essere minore di quella di fine');
            gui.ChiudiPagina();
        return;
        when others then
            gui.AggiungiPopup(false, 'Qualcosa è andato storto!');
            gui.ChiudiPagina();
        return;

    end statCorsePNP;


----------------------------modificaPrenotazione-----------------------------------------------
    procedure modificaPrenotazione (
        p_id_prenotazione in PRENOTAZIONI.IDprenotazione%TYPE default null,
        p_dataOra varchar2 default null,
        p_luogoPartenza in PRENOTAZIONI.LuogoPartenza%TYPE default null,
        p_luogoArrivo in PRENOTAZIONI.LuogoArrivo%TYPE default null,
        p_nPersone in PRENOTAZIONI.Npersone%TYPE default null,
        p_nPerDis in PRENOTAZIONEACCESSIBILE.NpersoneDisabili%TYPE default null,
        p_optionals in varchar2 default null,
        p_convenzioniCum in varchar2 default null,
        p_convenzioniNonCum in varchar2 default null,
        p_msgModifica number default null,
        p_idSess in SESSIONICLIENTI.IDSESSIONE%TYPE default null
    )
    is
        v_nonAnonima number;
        v_idClientePren NONANONIME.FK_Cliente%TYPE:=null;

        v_finePrenotazione date:=null;

        v_prenInfo r_PrenCategoria;
        v_taxiInfo r_TaxiCategoria;

        v_modificaEffettiva boolean;
        v_modificaEffettivaOptional boolean;

        v_optionalsIdRichiesti gui.StringArray :=gui.StringArray();
        v_strSelectedOptionalPren varchar2(100);

        v_optionalsNomePren gui.StringArray :=gui.StringArray();
        v_optionalsIdPren gui.StringArray :=gui.StringArray();
        v_optionalsNomeOfferti gui.StringArray :=gui.StringArray();
        v_optionalsIdOfferti gui.StringArray :=gui.StringArray();
        v_optionalsNomeTaxi gui.StringArray :=gui.StringArray();
        v_optionalsIdTaxi gui.StringArray :=gui.StringArray();

        v_convenzioniNomePrenCum gui.StringArray :=gui.StringArray();
        v_convenzioniIdPrenCum gui.StringArray :=gui.StringArray();
        v_convenzioniNomePrenNonCum gui.StringArray :=gui.StringArray();
        v_convenzioniIdPrenNonCum gui.StringArray :=gui.StringArray();

        v_convenzioniNomeClienteCum gui.StringArray :=gui.StringArray();
        v_convenzioniIdClienteCum gui.StringArray :=gui.StringArray();
        v_convenzioniNomeClienteNonCum gui.StringArray :=gui.StringArray();
        v_convenzioniIdClienteNonCum gui.StringArray :=gui.StringArray();

        v_convenzioniCumIdRichieste gui.StringArray :=gui.StringArray();
        v_convenzioniNonCumIdRichieste gui.StringArray :=gui.StringArray();
        convnenzioneOk convenzioni.idconvenzione%type;

        v_strSelectedConvenzioniCumlPren varchar2(100);
        v_strSelectedConvenzioneNonCumPren varchar2(10);

        head gui.StringArray :=gui.StringArray();

    begin

        gui.ApriPagina('Modifica prenotazione', p_idSess);
        gui.aCapo();
        gui.AggiungiIntestazione('Modifica prenotazione '|| p_id_prenotazione, 'h1');
        gui.aCapo();

        if SessionHandler.getRuolo(p_idSess) is null or ((SessionHandler.getRuolo(p_idSess) <> 'Operatore') AND (SessionHandler.getRuolo(p_idSess) <> 'Cliente'))
        then raise NoPermessi;
        end if;

        if p_msgModifica is not null then
            case p_msgModifica
            when 1 then gui.AggiungiPopup(false, 'Impossibile modificare la prenotazione perché i parametri inseriti non sono corretti.');
            when 2 then gui.AggiungiPopup(false, 'Impossibile modificare la prenotazione perchè le convenzioni selezionate non sono corrette.');
            end case;
        end if;

        --raccolta dati sulla prenotazione
        begin
        select *
        into v_prenInfo
        from Prenotazioni P
        left join PrenotazioneStandard PrenS on P.IDprenotazione = PrenS.FK_Prenotazione
        left join PrenotazioneAccessibile PrenA on P.IDprenotazione = PrenA.FK_Prenotazione
        left join PrenotazioneLusso PrenL on P.IDprenotazione = PrenL.FK_Prenotazione
        where P.IDprenotazione=p_id_prenotazione;
        EXCEPTION
            when NO_DATA_FOUND then raise PrenNonEsiste;
            when others then raise;
        end;

        --controlli ruolo e se e tipo
        select count(*) into v_nonAnonima from NonAnonime where FK_Prenotazione=p_id_prenotazione;
        --se è nonAnonima ritorna 1

        --controllo che il cliente che effettua la modifica sia lo stesso che abbia effettuato la prenotazione
        if SessionHandler.getRuolo(p_idSess) = 'Cliente'
        then
            if v_nonAnonima=0 --la prenotazione è anonima, il cliente non la può modificare perchè sicuramente non è sua
            then raise NoPermessi;
            else
                select FK_Cliente into v_idClientePren from NonAnonime where FK_Prenotazione=p_id_prenotazione;
                if v_idClientePren <> SessionHandler.getIDuser(p_idSess)
                then raise NoPermessi;
                end if;
            end if;
        elsif SessionHandler.getRuolo(p_idSess) = 'Operatore' AND v_nonAnonima=1
            --un operatore, invece, può modificare sia le prenotazioni anonime che quelle non anonime,
            --se la prenotazione non è anonima, prendo l'id del cliente che l'ha effettuata
            then
            select FK_Cliente into v_idClientePren from NonAnonime where FK_Prenotazione=p_id_prenotazione;
        end if;

        v_finePrenotazione:=v_prenInfo.r_dataOra + NUMTODSINTERVAL (v_prenInfo.r_durata, 'MINUTE');

        --se la prenotazione è di lusso prendo anche gli optional
        if v_prenInfo.r_PrenLss is not null
        then
            --optional richiesti dalla prenotazione
            for x in (
                select *
                from Optionals O
                join RichiestePrenLusso RL on O.IDoptionals=RL.FK_Optionals
                where RL.FK_Prenotazione=v_prenInfo.r_IDprenotazione
            ) loop
                v_strSelectedOptionalPren:=x.IDoptionals||';'||v_strSelectedOptionalPren;
                v_optionalsNomePren.extend;
                v_optionalsNomePren(v_optionalsNomePren.count) := x.Nome;
                v_optionalsIdPren.extend;
                v_optionalsIdPren(v_optionalsIdPren.count) := x.IDoptionals;
            end loop;

            if length(v_strSelectedOptionalPren)>0
            then --tolgo l'ultimo ;
                v_strSelectedOptionalPren:=substr(v_strSelectedOptionalPren, 1, length(v_strSelectedOptionalPren)-1);
            end if;

            --optional offerti dal sistema
            for x in (
                select distinct o.Nome, o.IDoptionals
                from Optionals o
                join PossiedeTaxiLusso ptl on o.IDoptionals=ptl.FK_optionals
            ) loop
                v_optionalsNomeOfferti.extend();
                v_optionalsNomeOfferti(v_optionalsNomeOfferti.count):=x.Nome;
                v_optionalsIdOfferti.extend();
                v_optionalsIdOfferti(v_optionalsIdOfferti.count):=x.IDoptionals;
            end loop;

        end if;

        --raccolta dati convenzioni
        if v_nonAnonima=1
        then
            --prendo tutte le convenzioni usate per questa prenotazione
            v_convenzioniNomePrenCum:=gui.StringArray();
            v_convenzioniIdPrenCum:=gui.StringArray();
            v_convenzioniNomePrenNonCum:=gui.StringArray();
            v_convenzioniIdPrenNonCum:=gui.StringArray();

            v_convenzioniNomeClienteCum:= gui.StringArray();
            v_convenzioniIdClienteCum:= gui.StringArray();
            v_convenzioniNomeClienteNonCum:= gui.StringArray();
            v_convenzioniIdClienteNonCum:= gui.StringArray();

            for x in (
                select C.Nome, C.IDconvenzione, C.cumulabile
                from Convenzioni C
                join ConvenzioniApplicate CA on C.IDconvenzione=CA.FK_Convenzione
                where CA.FK_NonAnonime=v_prenInfo.r_IDprenotazione
            ) loop
                if x.cumulabile=1 then
                    v_strSelectedConvenzioniCumlPren:=x.IDconvenzione||';'||v_strSelectedConvenzioniCumlPren;
                    v_convenzioniNomePrenCum.extend;
                    v_convenzioniNomePrenCum(v_convenzioniNomePrenCum.count):=x.Nome;
                    v_convenzioniIdPrenCum.extend;
                    v_convenzioniIdPrenCum(v_convenzioniIdPrenCum.count):=x.IDconvenzione;
                else
                    v_convenzioniNomePrenNonCum.extend;
                    v_convenzioniNomePrenNonCum(v_convenzioniNomePrenNonCum.count):=x.Nome;
                    v_convenzioniIdPrenNonCum.extend;
                    v_convenzioniIdPrenNonCum(v_convenzioniIdPrenNonCum.count):=x.IDconvenzione;
                end if;
            end loop;

            if length(v_strSelectedConvenzioniCumlPren)>0
            then --tolgo l'ultimo ;
                v_strSelectedConvenzioniCumlPren:=substr(v_strSelectedConvenzioniCumlPren, 1, length(v_strSelectedConvenzioniCumlPren)-1);
            end if;

            --prendo tutte le convenzioni che l'utente può usare per quella prenotazione
            for x in (
                select C.Nome, C.IDconvenzione, C.cumulabile
                from Convenzioni C
                join ConvenzioniClienti CC on C.IDconvenzione= CC.FK_Convenzione
                where CC.FK_Cliente=v_idClientePren AND
                    to_char(v_prenInfo.r_dataOra, 'yyyy-mm-dd') >= to_char(C.DataInizio, 'yyyy-mm-dd') AND
                    to_char(v_prenInfo.r_dataOra, 'yyyy-mm-dd') <= to_char(C.DataFine, 'yyyy-mm-dd')
            ) loop

                if x.cumulabile=1 then
                    v_convenzioniNomeClienteCum.extend;
                    v_convenzioniNomeClienteCum(v_convenzioniNomeClienteCum.count):=x.Nome;
                    v_convenzioniIdClienteCum.extend;
                    v_convenzioniIdClienteCum(v_convenzioniIdClienteCum.count):=x.IDconvenzione;
                else
                    v_convenzioniNomeClienteNonCum.extend;
                    v_convenzioniNomeClienteNonCum(v_convenzioniNomeClienteNonCum.count):=x.Nome;
                    v_convenzioniIdClienteNonCum.extend;
                    v_convenzioniIdClienteNonCum(v_convenzioniIdClienteNonCum.count):=x.IDconvenzione;
                end if;
            end loop;

        end if;

        --stampa tabella di riepilogo prenotazione
        if v_nonAnonima=1
        then
            head:= gui.StringArray('ID prenotazione', 'Data', 'Orario di partenza', 'Luogo di partenza', 'Orario previsto di arrivo', 'Luogo di arrivo', 'Numero di persone', 'Modificata', 'Stato', 'Convenzioni cumulabili', 'Convenzioni non cumulabili');
        else
            head:= gui.StringArray('ID prenotazione', 'Data', 'Orario di partenza', 'Luogo di partenza', 'Orario previsto di arrivo', 'Luogo di arrivo', 'Numero di persone', 'Modificata', 'Stato');
        end if;

        gui.ApriTabella(head);
        gui.AggiungiRigaTabella();
        gui.AggiungiElementoTabella('' || v_prenInfo.r_IDprenotazione || '');
        gui.AggiungiElementoTabella(to_char(v_prenInfo.r_dataOra, 'YYYY-MM-DD'));
        gui.AggiungiElementoTabella(to_char(v_prenInfo.r_dataOra, 'HH24:MI'));
        gui.AggiungiElementoTabella('' || v_prenInfo.r_luogoPartenza || '');
        gui.AggiungiElementoTabella(to_char(v_finePrenotazione, 'HH24:MI'));
        gui.AggiungiElementoTabella('' || v_prenInfo.r_luogoArrivo || '');
        gui.AggiungiElementoTabella('' || v_prenInfo.r_nPersone || '');
        gui.AggiungiElementoTabella(case when v_prenInfo.r_modificata=0 then 'no' else 'sì' end);
        gui.AggiungiElementoTabella('' || v_prenInfo.r_Stato || '');

        if v_nonAnonima=1
        then
            if v_convenzioniNomePrenCum.count<>0 then
                utility.dropDownInformation(v_convenzioniNomePrenCum, 'convenzioni prenotazione');
            else gui.AggiungiElementoTabella('—');
            end if;

            if v_convenzioniNomePrenNonCum.count<>0 then
                utility.dropDownInformation(v_convenzioniNomePrenNonCum, 'convenzioni prenotazione');
            else gui.AggiungiElementoTabella('—');
            end if;

        end if;

        gui.ChiudiRigaTabella();
        gui.ChiudiTabella();
        gui.aCapo();


        --tabella di riepilogo categoria prenotazione
        case
            when v_prenInfo.r_PrenStd is not null
                then head:=gui.StringArray('Categoria');
                    gui.ApriTabella(head);
                    gui.AggiungiRigaTabella();
                    gui.AggiungiElementoTabella('Standard');
                    gui.ChiudiRigaTabella();
                    gui.ChiudiTabella();
            when v_prenInfo.r_PrenAcc is not null
                then head:=gui.StringArray('Categoria', 'Numero persone disabili');
                    gui.ApriTabella(head);
                    gui.AggiungiRigaTabella();
                    gui.AggiungiElementoTabella('Accessibile');
                    gui.AggiungiElementoTabella('' || v_prenInfo.r_NperDis || '');
                    gui.ChiudiRigaTabella();
                    gui.ChiudiTabella();
            when v_prenInfo.r_PrenLss is not null
                then
                    head:=gui.StringArray('Categoria', 'Optional richiesti');
                    gui.ApriTabella(head);
                    gui.AggiungiRigaTabella();
                    gui.AggiungiElementoTabella('Lusso');

                    if v_optionalsNomePren.count<>0 then
                        utility.dropDownInformation(v_optionalsNomePren, 'optionals richiesti');
                    else gui.AggiungiElementoTabella('—');
                    end if;

                    gui.ChiudiRigaTabella();
                    gui.ChiudiTabella();
        end case;


        --raccolta dati sul taxi assegnato alla prenotazione
        if v_prenInfo.r_stato = 'accettata'
        then
            begin
            select Ta.IDtaxi, Ta.Nposti, Ta.tariffa, TaA.NpersoneDisabili
            into v_taxiInfo
            from Taxi Ta
            left join TaxiStandard TaS on Ta.IDtaxi=TaS.FK_taxi
            left join TaxiAccessibile TaA on Ta.IDtaxi=TaA.FK_taxi
            left join TaxiLusso TaL on Ta.IDtaxi=TaL.FK_taxi
            left join PrenotazioneStandard PrenS on PrenS.FK_taxi=Ta.IDtaxi
            left join PrenotazioneAccessibile PrenA on PrenA.FK_taxiAccessibile=Ta.IDtaxi
            left join PrenotazioneLusso PrenL on PrenL.FK_taxi=Ta.IDtaxi
            where
                (PrenS.FK_prenotazione=v_prenInfo.r_IDprenotazione or PrenA.FK_prenotazione=v_prenInfo.r_IDprenotazione or PrenL.FK_prenotazione=v_prenInfo.r_IDprenotazione)
                AND
                ((TaS.FK_Taxi is not null AND TaS.FK_taxi=Ta.IDtaxi) OR
                (TaA.FK_Taxi is not null AND TaA.FK_taxi=Ta.IDtaxi) OR
                (TaL.FK_Taxi is not null AND TaL.FK_taxi=Ta.IDtaxi));
            EXCEPTION
            when NO_DATA_FOUND then raise ErroreParametri;
            when others then raise;
            end;

            --se la prenotazione è di lusso prendo anche gli optional offerti dal taxi a cui è assegnata la prenotazione
            if v_prenInfo.r_taxiLss is not null
            then
                v_optionalsNomeTaxi:= gui.StringArray();
                v_optionalsIdTaxi:= gui.StringArray();
                for x in (
                    select *
                    from Optionals O
                    join PossiedeTaxiLusso PTL on O.IDoptionals=PTL.FK_Optionals
                    where PTL.FK_TaxiLusso=v_prenInfo.r_taxiLss
                ) loop
                    v_optionalsNomeTaxi.extend;
                    v_optionalsNomeTaxi(v_optionalsNomeTaxi.count) := x.Nome;
                    v_optionalsIdTaxi.extend;
                    v_optionalsIdTaxi(v_optionalsIdTaxi.count) := x.IDoptionals;
                end loop;
            end if;
            gui.aCapo();


            --tabella di riepilogo taxi
            if  v_prenInfo.r_PrenStd is not null
                then head:=gui.StringArray('ID taxi', 'Numero posti disponibili', 'Tariffa');
            elsif v_prenInfo.r_PrenAcc is not null
                then head:=gui.StringArray('ID taxi', 'Numero posti disponibili', 'Tariffa', 'Numero posti disabili disponibili');
            elsif v_prenInfo.r_PrenLss is not null
                then head:=gui.StringArray('ID taxi', 'Numero posti disponibili', 'Tariffa', 'Optional offerti dal taxi');
            end if;

            gui.ApriTabella(head);
            gui.AggiungiRigaTabella();
            gui.AggiungiElementoTabella(v_taxiInfo.r_IDtaxi);
            gui.AggiungiElementoTabella(v_taxiInfo.r_nPerTaxi);
            gui.AggiungiElementoTabella(to_char(v_taxiInfo.r_tariffa, '0.00')|| ' eur/min');

            if v_prenInfo.r_PrenAcc is not null
                then gui.AggiungiElementoTabella(v_taxiInfo.r_nPerDisTaxi);
            elsif v_prenInfo.r_PrenLss is not null
                then
                --optional offerti dal taxi
                if v_optionalsNomeTaxi.count<>0 then
                    utility.dropDownInformation(v_optionalsNomeTaxi, 'optionals del taxi');
                else gui.AggiungiElementoTabella('—');
                end if;
            end if;
            gui.ChiudiRigaTabella();
            gui.ChiudiTabella();
        end if;


        --compilare i campi per la modifica
        if p_dataOra is null or p_luogoPartenza is null or p_luogoArrivo is null or p_nPersone is null
        then

            if SYSDATE >= v_prenInfo.r_dataOra then raise PrenPassata; end if;
            if SYSDATE >= (v_prenInfo.r_dataOra - interval '4' HOUR) then raise PrenNonModificabile; end if;
            if v_prenInfo.r_modificata=1 then raise PrenGiaModificata; end if;
            if (v_prenInfo.r_stato = 'annullata') OR (v_prenInfo.r_stato = 'rifiutata') then raise PrenAnnRif; end if;

            gui.aCapo();
            gui.AggiungiForm(url=>u_root||'.modificaPrenotazione');
            gui.aggiungigruppoinput();

            gui.AggiungiLabel('DO', 'Data e ora');
            gui.AggiungiCampoForm('datetime-local', nome=>'p_dataOra', required=>true, ident=>'DO', placeholder=> 'Data e ora', value=>to_char(v_prenInfo.r_dataOra, 'YYYY-MM-DD HH24:MI'), minimo=>to_char(sysdate+interval '10' minute,'YYYY-MM-DD HH24:MI'), massimo=>to_char(sysdate+7,'YYYY-MM-DD HH24:MI'));
            gui.AggiungiLabel('LdP', 'Luogo di partenza');
            gui.AggiungiCampoForm('text', nome=>'p_luogoPartenza', required=>true, ident=>'LdP', placeholder=> 'Luogo di Partenza', value=>v_prenInfo.r_luogoPartenza);
            gui.AggiungiLabel('LdA', 'Luogo di arrivo');
            gui.AggiungiCampoForm('text', nome=>'p_luogoArrivo', required=>true, ident=>'LdA', placeholder=> 'Luogo di Arrivo', value=>v_prenInfo.r_luogoArrivo);
            gui.AggiungiLabel('nP', 'Numero di persone');
            gui.AggiungiCampoForm('number', nome=>'p_nPersone', required=>true, ident=>'nP', placeholder=>'Numero di persone', value=>v_prenInfo.r_nPersone, minimo=>1, massimo=>8);

            if v_prenInfo.r_PrenAcc is not null
            then
                gui.AggiungiLabel('nPD', 'Numero di persone disabili');
                gui.AggiungiCampoForm('number', nome=>'p_nPerDis', required=>true, ident=>'nP', placeholder=>'Numero di persone disabili', value=>v_prenInfo.r_NperDis, minimo=>1, massimo=>2);
            end if;

            if v_prenInfo.r_PrenLss is not null and v_optionalsIdOfferti.count>0
            then -- sono pre-selezionati gli optionals richiesti nella prenotazione
                gui.aggiungiSelezioneMultipla('optional', 'optionals', v_optionalsIdOfferti, v_optionalsNomeOfferti, 'p_optionals', v_optionalsIdPren, 'opt');
            end if;

            if v_nonAnonima=1
            then
                if v_convenzioniNomeClienteCum.count > 0
                then -- sono pre-selezionate le convenzioni cumulabili richieste nella prenotazione
                    gui.aggiungiSelezioneMultipla('convenzioni cumulabili', 'convenzioni cumulabili', v_convenzioniIdClienteCum, v_convenzioniNomeClienteCum, 'p_convenzioniCum', v_convenzioniIdPrenCum, 'conv');
                end if;

                if v_convenzioniNomeClienteNonCum.count > 0
                then
                    if v_convenzioniIdPrenNonCum.count>0
                    then -- è pre-selezionata la convenzione cumulabile richiesta nella prenotazione
                        gui.aggiungiSelezioneSingola(v_convenzioniNomeClienteNonCum,v_convenzioniIdClienteNonCum,'convenzioni non cumulabili',ident=>'p_convenzioniNonCum', optionSelected=>v_convenzioniIdPrenNonCum(1), firstNull=>true);
                    else gui.aggiungiSelezioneSingola(v_convenzioniNomeClienteNonCum,v_convenzioniIdClienteNonCum,'convenzioni non cumulabili',ident=>'p_convenzioniNonCum', firstNull=>true);
                    end if;
                end if;
            end if;

            gui.AggiungiCampoFormHidden('number', 'p_id_prenotazione',v_prenInfo.r_IDprenotazione);
            gui.AggiungiCampoFormHidden('text', 'p_idSess',p_idSess);
            gui.AggiungiCampoFormHidden('text', 'p_optionals', v_strSelectedOptionalPren);
            gui.AggiungiCampoFormHidden('text', 'p_convenzioniCum', v_strSelectedConvenzioniCumlPren);

            gui.aggiungiBottoneSubmit('Modifica');
            gui.ChiudiGruppoInput();
            gui.ChiudiForm();


        else --effettuare le modifiche

            if p_nPerDis is not null and p_optionals is not null then raise ErroreParametri; end if;

            savepoint savepointModifica;

            v_modificaEffettiva:=false; --variabile per controllare se cambiano davvero i dati
            if to_char(v_prenInfo.r_dataOra, 'YYYY-MM-DD HH24:MI')<>to_char(to_date(p_dataora,'YYYY-MM-DD"T"HH24:MI'), 'YYYY-MM-DD HH24:MI')
            then
                if to_char(to_date(p_dataora,'YYYY-MM-DD"T"HH24:MI'), 'YYYY-MM-DD HH24:MI') < to_char(sysdate, 'YYYY-MM-DD HH24:MI')
                then raise ErroreParametri;
                end if;
                update prenotazioni p set p.DataOra=to_date(to_char(to_date(p_dataora,'YYYY-MM-DD"T"HH24:MI'), 'YYYY-MM-DD HH24:MI'), 'YYYY-MM-DD HH24:MI'), p.stato='pendente', p.durata=FLOOR(DBMS_RANDOM.VALUE(10, 30)) where p.IDprenotazione=v_prenInfo.r_IDprenotazione;
                utility.setTaxiNull(v_prenInfo.r_IDprenotazione);
                v_modificaEffettiva:=true;
            end if;

            if LOWER(replace(v_prenInfo.r_luogoPartenza, ' ', '')) <> (LOWER(replace(p_luogoPartenza, ' ', '')))
            then
                update prenotazioni p set p.LuogoPartenza=p_luogoPartenza, p.stato='pendente', p.durata=FLOOR(DBMS_RANDOM.VALUE(10, 30)) where p.IDprenotazione=v_prenInfo.r_IDprenotazione;
                utility.setTaxiNull(v_prenInfo.r_IDprenotazione);
                v_modificaEffettiva:=true;
            end if;

            if LOWER(replace(v_prenInfo.r_luogoArrivo, ' ', '')) <> (LOWER(replace(p_luogoArrivo, ' ', '')))
            then
                update prenotazioni p set p.LuogoArrivo=p_luogoArrivo, p.stato='pendente', p.durata=FLOOR(DBMS_RANDOM.VALUE(10, 30)) where p.IDprenotazione=v_prenInfo.r_IDprenotazione;
                utility.setTaxiNull(v_prenInfo.r_IDprenotazione);
                v_modificaEffettiva:=true;
            end if;

            if v_prenInfo.r_nPersone <> p_nPersone
            then
                if p_nPersone<1 or p_nPersone>8 then raise ErroreParametri; end if;
                if (v_prenInfo.r_PrenAcc is not null) and (p_nPersone > 4) then raise ErroreParametri; end if;
                if (v_prenInfo.r_stato='accettata') AND (p_npersone>v_taxiInfo.r_nPerTaxi)
                then
                    update prenotazioni p set p.stato='pendente' where p.IDprenotazione=v_prenInfo.r_IDprenotazione;
                    utility.setTaxiNull(v_prenInfo.r_IDprenotazione);
                end if;
                update prenotazioni p set p.Npersone=p_nPersone where p.IDprenotazione=v_prenInfo.r_IDprenotazione;
                v_modificaEffettiva:=true;
            end if;

            --prenotazione accessibile
            if (v_prenInfo.r_NperDis is not null) AND (v_prenInfo.r_NperDis <> p_nPerDis)
            then
                if p_NperDis<1 or p_NperDis>2 then raise ErroreParametri; end if;
                if (v_prenInfo.r_stato='accettata') AND (p_nPerDis>v_taxiInfo.r_nPerDisTaxi)
                then
                    update prenotazioni p set p.stato='pendente' where p.IDprenotazione=v_prenInfo.r_IDprenotazione;
                    utility.setTaxiNull(v_prenInfo.r_IDprenotazione);
                end if;
                update PrenotazioneAccessibile pa set pa.NpersoneDisabili=p_nPerDis;
                v_modificaEffettiva:=true;
            end if;

            --se la pren è di lusso e non chiedo nessun optional ma prima ne richiedevo qualcuno, li devo cancellare
            if v_prenInfo.r_PrenLss is not null and p_optionals is null and v_optionalsIdPren.count>0
            then
                delete from RichiestePrenLusso where fk_prenotazione=v_prenInfo.r_IDprenotazione;
                v_modificaEffettiva:=true;
            end if;

            -- se la prenotazione è di lusso e richede degli optional
            if v_prenInfo.r_PrenLss is not null and p_optionals is not null
            then

                v_modificaEffettivaOptional:=false; --variabile per controllare che siano davvero stati modificati degli optional
                v_optionalsIdRichiesti:=utility.stringToArray(p_optionals, ';');

                --se il taxi assegnato non possiede più gli optional richiesti dopo la modifica, la prenotazione diventa pendente
                if v_prenInfo.r_stato='accettata' AND not(utility.taxiPossiedeOptionals(v_prenInfo.r_taxiLss, v_optionalsIdRichiesti))
                then
                    update prenotazioni p set p.stato='pendente' where p.IDprenotazione=v_prenInfo.r_IDprenotazione;
                    utility.setTaxiNull(v_prenInfo.r_IDprenotazione);
                end if;

                --per ogni optional che era richiesto prima della modifica, se adesso non viene più richiesto viene cancellato
                for i in 1..v_optionalsIdPren.count loop
                if not(utility.esiste(v_optionalsIdRichiesti, v_optionalsIdPren(i)))
                then
                    delete from RichiestePrenLusso where fk_prenotazione=v_prenInfo.r_IDprenotazione and fk_optionals=v_optionalsIdPren(i);
                    v_modificaEffettiva:=true; v_modificaEffettivaOptional:=true;
                end if;
                end loop;

                --per ogni optional richiesto, se prima della modifica non era richiesto viene aggiunto
                for i in 1..v_optionalsIdRichiesti.count loop
                if not(utility.esiste(v_optionalsIdPren, v_optionalsIdRichiesti(i)))
                then
                    insert into RichiestePrenLusso values (v_prenInfo.r_IDprenotazione, v_optionalsIdRichiesti(i));
                    v_modificaEffettiva:=true; v_modificaEffettivaOptional:=true;
                end if;
                end loop;

                -- se ho modidificato gli optional e non esiste nessun taxi che offre gli optional richiesti, la prenotazione viene rifiutata
                if v_modificaEffettivaOptional=true and not(utility.esisteTaxiPossiedeOptionals(v_optionalsIdRichiesti))
                then
                    update prenotazioni p set p.stato='rifiutata' where p.IDprenotazione=v_prenInfo.r_IDprenotazione;
                    utility.setTaxiNull(v_prenInfo.r_IDprenotazione);
                end if;

            end if;


            if v_nonAnonima=1
            then
                --se richiedo sia convenzioni cumulabili che non cumulabili, errore
                if p_convenzioniCum is not null and p_convenzioniNonCum is not null then raise ErroreConvenzioni; end if;

                --se ora non richiedo nessuna convenzione cumulabile e prima avevo richiesto qualcosa, elimino tutte le richieste passate
                if p_convenzioniCum is null and v_convenzioniIdPrenCum.count>0
                then
                    delete from ConvenzioniApplicate where fk_nonanonime=v_prenInfo.r_IDprenotazione;
                    v_modificaEffettiva:=true;
                end if;

                --se ora non richiedo nessuna convenzione non cumulabili e prima avevo richiesto qualcosa, elimino tutte le richieste passate
                if p_convenzioniNonCum is null and v_convenzioniIdPrenNonCum.count>0
                then
                    delete from ConvenzioniApplicate where fk_nonanonime=v_prenInfo.r_IDprenotazione;
                    v_modificaEffettiva:=true;
                end if;

                --se richiedo convenzioni cumulabili
                if p_convenzioniCum is not null
                then
                    --convenzioni richieste
                    v_convenzioniCumIdRichieste:=utility.stringToArray(p_convenzioniCum, ';');

                    for i in 1..v_convenzioniCumIdRichieste.count loop
                        begin
                        select C.IDconvenzione
                        into convnenzioneOk
                        from convenzioni C
                        join convenzioniClienti CC on C.IDconvenzione=CC.fk_convenzione
                        where C.IDconvenzione=v_convenzioniCumIdRichieste(i) and
                                CC.fk_cliente=v_idClientePren and
                                to_char(v_prenInfo.r_dataOra, 'yyyy-mm-dd') >= to_char(C.DataInizio, 'yyyy-mm-dd') AND
                                to_char(v_prenInfo.r_dataOra, 'yyyy-mm-dd') <= to_char(C.DataFine, 'yyyy-mm-dd');
                        EXCEPTION
                        when NO_DATA_FOUND then raise ErroreConvenzioni;
                        when others then raise;
                        end;
                    end loop;

                    --per ogni richiesta fatta prima, se ora non viene più richiesta, la elimino
                    for i in 1..v_convenzioniIdPrenCum.count loop
                        if not(utility.esiste(v_convenzioniCumIdRichieste, v_convenzioniIdPrenCum(i)))
                        then
                            delete from ConvenzioniApplicate where fk_nonanonime=v_prenInfo.r_IDprenotazione and fk_convenzione=v_convenzioniIdPrenCum(i);
                            v_modificaEffettiva:=true;
                        end if;
                    end loop;

                    --per ogni richiesta, se prima non veniva richiesta, la inserisco
                    for i in 1..v_convenzioniCumIdRichieste.count loop
                        if not(utility.esiste(v_convenzioniIdPrenCum, v_convenzioniCumIdRichieste(i)))
                        then
                            insert into ConvenzioniApplicate values (v_convenzioniCumIdRichieste(i), v_prenInfo.r_IDprenotazione);
                            v_modificaEffettiva:=true;
                        end if;
                    end loop;

                end if;

                if p_convenzioniNonCum is not null
                then
                    v_convenzioniNonCumIdRichieste:=utility.stringToArray(p_convenzioniNonCum, ';');
                    if v_convenzioniNonCumIdRichieste.count>1 then raise ErroreConvenzioni; end if;

                    begin
                    select C.IDconvenzione
                    into convnenzioneOk
                    from convenzioni C
                    join convenzioniClienti CC on C.IDconvenzione=CC.fk_convenzione
                    where C.IDconvenzione=v_convenzioniNonCumIdRichieste(1) and
                            CC.fk_cliente=v_idClientePren and
                            to_char(v_prenInfo.r_dataOra, 'yyyy-mm-dd') >= to_char(C.DataInizio, 'yyyy-mm-dd') AND
                            to_char(v_prenInfo.r_dataOra, 'yyyy-mm-dd') <= to_char(C.DataFine, 'yyyy-mm-dd');
                    EXCEPTION
                    when NO_DATA_FOUND then raise ErroreConvenzioni;
                    when others then raise;
                    end;

                    -- se prima chiedeva qualcosa
                    if v_convenzioniIdPrenNonCum.count>0
                    then
                        if v_convenzioniNonCumIdRichieste(1) <> v_convenzioniIdPrenNonCum(1) --se la scelta è cambiata, viene aggiornata
                        then
                            delete from convenzioniapplicate where fk_nonanonime=v_prenInfo.r_IDprenotazione and fk_convenzione=v_convenzioniIdPrenNonCum(1);
                            insert into convenzioniapplicate values (v_convenzioniNonCumIdRichieste(1), v_prenInfo.r_IDprenotazione);
                            v_modificaEffettiva:=true;
                        end if;
                    else --se prima nonn chiedeva niente, inserisco la nuova
                        insert into convenzioniapplicate values (v_convenzioniNonCumIdRichieste(1), v_prenInfo.r_IDprenotazione);
                        v_modificaEffettiva:=true;
                    end if;

                end if;

            end if;

            commit;

            if v_modificaEffettiva=true
            then
                update prenotazioni p set p.modificata=1 where p.IDprenotazione=v_prenInfo.r_IDprenotazione;
                gui.reindirizza(u_root||'.visPren?p_idSess='||p_idSess||chr(38)||'p_id='||v_prenInfo.r_IDprenotazione||chr(38)||'p_visPrenBoolean=5'); --ci vuole un'altra var per quel pop up
                return;
            else
                gui.reindirizza(u_root||'.visPren?p_idSess='||p_idSess||chr(38)||'p_id='||v_prenInfo.r_IDprenotazione||chr(38)||'p_visPrenBoolean=6'); --ci vuole un'altra var per quel pop up
                return;
            end if;


        end if;

        gui.aCapo();
        gui.ChiudiPagina();

        EXCEPTION
            when PrenNonEsiste then
                gui.AggiungiPopup(false, 'La prenotazione non esiste.');
                gui.ChiudiPagina();
            return;
            when ErroreParametri then
                gui.reindirizza(u_root||'.modificaPrenotazione?p_idSess='||p_idSess||chr(38)||'p_id_prenotazione='||p_id_prenotazione||chr(38)||'p_msgModifica=1');
            return;
            when PrenNonModificabile then
                gui.reindirizza(u_root||'.visPren?p_idSess='||p_idSess||chr(38)||'p_id='||p_id_prenotazione||chr(38)||'p_visPrenBoolean=10');
            return;
            when PrenGiaModificata then
                gui.reindirizza(u_root||'.visPren?p_idSess='||p_idSess||chr(38)||'p_id='||p_id_prenotazione||chr(38)||'p_visPrenBoolean=11');
            return;
            when PrenAnnRif then
                gui.reindirizza(u_root||'.visPren?p_idSess='||p_idSess||chr(38)||'p_id='||p_id_prenotazione||chr(38)||'p_visPrenBoolean=8');
            return;
            when PrenPassata then
                gui.reindirizza(u_root||'.visPren?p_idSess='||p_idSess||chr(38)||'p_id='||p_id_prenotazione||chr(38)||'p_visPrenBoolean=9');
            return;
            when NoPermessi then
                gui.AggiungiPopup(false, 'Impossibile visualizzare questa pagina perchè l'||chr(39)||'utente non possiede i permessi corretti.');
                gui.ChiudiPagina();
            return;
            when ErroreConvenzioni then
                rollback to savepointModifica;
                gui.reindirizza(u_root||'.modificaPrenotazione?p_idSess='||p_idSess||chr(38)||'p_id_prenotazione='||p_id_prenotazione||chr(38)||'p_msgModifica=2');
            return;
            when others then
                rollback to savepointModifica;
                gui.AggiungiPopup(false, 'Qualcosa è andato storto!');
                gui.ChiudiPagina();
            return;
    end ModificaPrenotazione;
---------------------------------------------------------------------

 ---------------------------------Baffa-----------------------------------------

        PROCEDURE visualizzaPrenotazioni(
                p_idSess in SESSIONICLIENTI.IDSESSIONE%TYPE default null,
                p_id_prenotazione in PRENOTAZIONI.IDprenotazione%TYPE default null,
                p_data varchar2 default null,
                p_ora varchar2 default null,
                p_partenza in PRENOTAZIONI.LuogoPartenza%TYPE default null,
                p_persone in PRENOTAZIONI.Npersone%TYPE default null,
                p_arrivo in PRENOTAZIONI.LuogoArrivo%TYPE default null,
                p_stato in PRENOTAZIONI.Stato%TYPE default null,
                p_durata in PRENOTAZIONI.Durata%TYPE default null,
                p_modificata in PRENOTAZIONI.Modificata%TYPE default null,
                p_sub in varchar2 default null,
                p_id_annullata in PRENOTAZIONI.IDprenotazione%TYPE default null,
                p_tipoTaxi in varchar2 default null)
        is
                head gui.StringArray;
                ruolo varchar(10);
                datamax date;
                TipoTaxi varchar(15);
        begin

            -- Controllo che si stia cercando di accedere alla procedura con i giusti permessi
            ruolo := SessionHandler.getRuolo(p_idSess);
            if ruolo <> 'Operatore' or ruolo is null then
                raise NoPermessi;
            end if;

            --Reset Filtro
            if(p_sub = 'R') then gui.Reindirizza(u_root || '.visualizzaPrenotazioni' || '?p_idSess=' || p_idSess);
            end if;

            --Intestazione tabella
            head := gui.StringArray('ID', 'Luogo di Partenza', 'Data di Partenza', 'Ora di Partenza', 'Luogo di Arrivo',
                                    'Persone', 'Modificata','Stato','Durata','Tipo',' ');

            gui.ApriPagina('VisualizzaPrenotazioni',p_idSess);
            gui.AggiungiIntestazione('Visualizza Prenotazioni', 'h1');

            gui.aCapo();
            gui.aCapo();
            gui.aCapo();

            --Controllo se bisogna annullare la prenotazione
            if(p_sub = 'A') then

                --Controllo ci sia un margine di almeno 4 ore
                Select dataora into datamax from prenotazioni where IDPrenotazione = p_id_annullata;
                dataMax:= datamax - NUMTODSINTERVAL (4, 'HOUR');

                if(sysdate > datamax) then
                    gui.AggiungiPopup(false,'La prenotazione non può più essere annullata');
                else
                    gui.AggiungiPopup(true,'Prenotazione annullata con successo');
                    UPDATE Prenotazioni SET Stato = 'annullata' WHERE IDprenotazione = p_id_annullata;
                end if;
            end if;

            gui.aCapo();
            gui.aCapo();

            gui.ApriFormFiltro(u_root||'.visualizzaPrenotazioni');

            -- Campo hidden, ID_sessione
            gui.AggiungiCampoFormHidden('text', 'p_idSess', p_idSess);

            gui.AggiungiRigaTabella();
            gui.AggiungiCampoFormFiltro('number', 'p_id_prenotazione', '', 'ID', minimo => 1);
            gui.AggiungiCampoFormFiltro('text', 'p_partenza', '', 'Luogo di Partenza');
            gui.AggiungiCampoFormFiltro('date', 'p_data', '', 'Data di Partenza');
            gui.AggiungiCampoFormFiltro('time', 'p_ora', '', 'Ora di Partenza');
            gui.AggiungiCampoFormFiltro('text', 'p_arrivo', '', 'Luogo di Arrivo');
            gui.AggiungiCampoFormFiltro('submit', 'p_sub', 'F', 'Filtra');

            gui.ChiudiRigaTabella();
            gui.AggiungiRigaTabella();

            gui.AggiungiCampoFormFiltro('number', 'p_persone', '', 'Persone', minimo => 1, massimo => 8);

            gui.APRISELECTFORMFILTRO('p_modificata', 'Modificata');
            gui.AGGIUNGIOPZIONESELECT(0, false, 'non modificata');
            gui.AGGIUNGIOPZIONESELECT(1, false, 'modificata');
            gui.CHIUDISELECTFORMFILTRO;

            gui.APRISELECTFORMFILTRO('p_stato','Stato');

            --Serve?
            gui.AGGIUNGIOPZIONESELECT('', true, '');
            gui.AGGIUNGIOPZIONESELECT('accettata', false, 'accettata');
            gui.AGGIUNGIOPZIONESELECT('pendente', false, 'pendente');
            gui.AGGIUNGIOPZIONESELECT('rifiutata', false, 'rifiutata');
            gui.AGGIUNGIOPZIONESELECT('annullata', false, 'annullata');
            gui.CHIUDISELECTFORMFILTRO;

            gui.AggiungiCampoFormFiltro('number', 'p_durata', '', 'Durata', minimo => 0 );

            gui.APRISELECTFORMFILTRO('p_tipoTaxi','Categoria');

            --Serve?
            gui.AGGIUNGIOPZIONESELECT('', true, '');
            gui.AGGIUNGIOPZIONESELECT('Standard', false, 'Standard');
            gui.AGGIUNGIOPZIONESELECT('Accessibile', false, 'Accessibile');
            gui.AGGIUNGIOPZIONESELECT('Lusso', false, 'Lusso');
            gui.CHIUDISELECTFORMFILTRO;

            gui.AggiungiCampoFormFiltro('submit', 'p_sub', 'R', 'Reset');
            gui.chiudiRigaTabella();
            gui.chiudiFormFiltro();

            gui.aCapo();

            -- Tabella
            gui.ApriTabella(head);

            -- Body
            for x in (SELECT PRENOTAZIONI.*, PRENOTAZIONESTANDARD.FK_PRENOTAZIONE as Standard,
                                PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE as Accessibile, PRENOTAZIONELUSSO.FK_PRENOTAZIONE
                    FROM PRENOTAZIONI
                    LEFT JOIN
                        PRENOTAZIONESTANDARD ON PRENOTAZIONI.IDPRENOTAZIONE = PRENOTAZIONESTANDARD.FK_PRENOTAZIONE
                    LEFT JOIN
                        PRENOTAZIONELUSSO ON PRENOTAZIONI.IDPRENOTAZIONE = PRENOTAZIONELUSSO.FK_PRENOTAZIONE
                    LEFT JOIN
                        PRENOTAZIONEACCESSIBILE ON PRENOTAZIONI.IDPRENOTAZIONE = PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE
                    where (PRENOTAZIONI.IDPRENOTAZIONE = p_id_prenotazione or p_id_prenotazione is null)
                        and ((trunc(PRENOTAZIONI.DATAORA) = to_date(p_data, 'YYYY-MM-DD')) or p_data is null)
                        and (to_char(PRENOTAZIONI.DATAORA, 'HH24:MI') = p_ora or p_ora is null)
                        and (LOWER(replace(Prenotazioni.LUOGOPARTENZA,' ','')) LIKE LOWER(replace(('%'||p_partenza||'%'),' ','')) or p_partenza is null)
                        and (PRENOTAZIONI.Npersone = p_persone or p_persone is null)
                        and (LOWER(replace(Prenotazioni.LUOGOARRIVO, ' ', '')) LIKE LOWER(replace(('%'||p_arrivo||'%'),' ','')) or p_arrivo is null)
                        and (PRENOTAZIONI.STATO = p_stato or p_stato is null)
                        and (PRENOTAZIONI.MODIFICATA = p_modificata or p_modificata is null)
                        and (PRENOTAZIONI.DURATA = p_durata or p_durata is null)
                        and (((PRENOTAZIONESTANDARD.FK_PRENOTAZIONE is not null and p_tipoTaxi = 'Standard') or
                            (PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE is not null and p_tipoTaxi = 'Accessibile') or
                            (PRENOTAZIONELUSSO.FK_PRENOTAZIONE is not null and p_tipoTaxi = 'Lusso')) or p_tipoTaxi is null)
                )
                loop
                    gui.AggiungiRigaTabella();
                    gui.AggiungiElementoTabella('' || x.IDprenotazione || '');
                    gui.AggiungiElementoTabella(x.LuogoPartenza || '');
                    gui.AggiungiElementoTabella((to_char(x.DataOra,'DD-MM-YYYY')));
                    gui.AggiungiElementoTabella((to_char(x.DataOra, 'HH24:MI')));
                    gui.AggiungiElementoTabella('' || x.LuogoArrivo || '');
                    gui.AggiungiElementoTabella('' || x.Npersone || '');

                    case x.MODIFICATA
                                when 0 then gui.AGGIUNGIELEMENTOTABELLA('No');
                                when 1 then gui.AGGIUNGIELEMENTOTABELLA('Sì');
                                end case;

                    gui.AggiungiElementoTabella('' || x.Stato || '');
                    gui.AggiungiElementoTabella('' || x.Durata || '');

                    --Verifico il tipo della prenotazione
                    if (x.Standard is not null) THEN
                        TipoTaxi := 'Standard';
                    else if(x.Accessibile is not null) THEN
                        TipoTaxi := 'Accessibile';
                        else TipoTaxi := 'Lusso';
                        end if;
                    end if;

                    gui.AggiungiElementoTabella('' || TipoTaxi || '');

                    gui.apriElementoPulsanti();
                    gui.AggiungiPulsanteModifica(u_root || '.modificaPrenotazione?p_idSess=' || p_idSess || '&p_id_prenotazione=' || x.IDprenotazione || '');
                    gui.AggiungiPulsanteCancellazione(''''|| u_root || '.visualizzaPrenotazioni?p_idSess=' || p_idSess || '&p_sub=A' || '&p_id_annullata=' || x.IDprenotazione || '''');
                    gui.chiudiElementoPulsanti();

                    gui.ChiudiRigaTabella();
                end loop;

            gui.ChiudiTabella();
            gui.aCapo();
            gui.ChiudiPagina();

        end visualizzaprenotazioni;

        procedure annullaPren(
            p_idSess in SESSIONICLIENTI.IDSESSIONE%TYPE default null,
            p_id_prenotazione in PRENOTAZIONI.IDprenotazione%TYPE default null
        )
        is
            datamax date;
            infoPren PRENOTAZIONI%ROWTYPE;
        begin
            --Controllo ci sia un margine di almeno 4 ore
            Select * into infoPren from prenotazioni where IDPrenotazione = p_id_prenotazione;
            dataMax:= infoPren.DataOra - NUMTODSINTERVAL (4, 'HOUR');

            if(sysdate > datamax or infoPren.MODIFICATA = 1 or infoPren.Stato = 'annullata') then

                gui.reindirizza(u_root || '.visPren?p_idSess=' || p_idSess || '&p_visPrenBoolean=' || 4);
            else
                UPDATE Prenotazioni SET Stato = 'annullata' WHERE IDprenotazione = p_id_prenotazione;
                gui.reindirizza(u_root || '.visPren?p_idSess=' || p_idSess || '&p_visPrenBoolean=' || 3);
            end if;
        end annullaPren;

        procedure visualizzaPrenotazionitaxi(
            p_idSess in SESSIONICLIENTI.IDSESSIONE%TYPE default null,
            p_id_taxi in TAXI.IDtaxi%TYPE default null,
            p_id_prenotazione in PRENOTAZIONI.IDprenotazione%TYPE default null,
            p_data varchar2 default null,
            p_ora varchar2 default null,
            p_partenza in PRENOTAZIONI.LuogoPartenza%TYPE default null,
            p_persone in PRENOTAZIONI.Npersone%TYPE default null,
            p_arrivo in PRENOTAZIONI.LuogoArrivo%TYPE default null,
            p_stato in PRENOTAZIONI.Stato%TYPE default null,
            p_durata in PRENOTAZIONI.Durata%TYPE default null,
            p_modificata in PRENOTAZIONI.Modificata%TYPE default null,
            p_sub in varchar2 default null,
            p_id_annullata in PRENOTAZIONI.IDprenotazione%TYPE default null)
        is
            head gui.StringArray;
            ruolo varchar(10);
            righe int;
            TipoTaxi varchar(15);
            datamax date;
        begin

            -- Controllo che si stia cercando di accedere alla procedura con i giusti permessi
            ruolo := SessionHandler.getRuolo(p_idSess);
            if ruolo <> 'Operatore' or ruolo is null then
                raise NoPermessi;
            end if;

            --Reset Filtro
            if(p_sub = 'R') then gui.Reindirizza(u_root || '.visualizzaPrenotazioniTaxi' || '?p_idSess=' || p_idSess || '&p_id_taxi=' || p_id_taxi);
            end if;

            head := gui.StringArray('ID', 'Luogo di Partenza', 'Data di Partenza', 'Ora di Partenza', 'Luogo di Arrivo',
                                    'Persone', 'Modificata','Stato','Durata',' ');

            gui.ApriPagina('VisualizzazionePrenotazioniTaxi',p_idSess);

            gui.AggiungiIntestazione('Visualizza Prenotazioni', 'h1');
            gui.AggiungiIntestazione('Taxi ' || p_id_taxi ||'', 'h1');

            --Verifico categoria di taxi
            Select count(*) Into Righe From Taxi,TaxiStandard Where Taxi.idTaxi = TaxiStandard.FK_Taxi;

            if(Righe>0) then
                TipoTaxi := 'Standard';
            else
                Select count(*) Into Righe From Taxi,TaxiAccessibile Where Taxi.idTaxi = TaxiAccessibile.FK_Taxi;
                if(Righe>0) then TipoTaxi := 'Accessibile';
                else
                    Select count(*) Into Righe From Taxi,TaxiLusso Where Taxi.idTaxi = TaxiLusso.FK_Taxi;
                    if(Righe>0) then TipoTaxi := 'Lusso';
                    end if;
                end if;
            end if;

            gui.AggiungiIntestazione('Categoria ' || TipoTaxi ||'', 'h3', 'text');

            gui.aCapo();
            gui.aCapo();
            gui.aCapo();

            --Controllo se bisogna annullare la prenotazione
            if(p_sub = 'A') then

                --Controllo che ci sia un margine di almeno 4 ore
                Select dataora into datamax from prenotazioni where IDPrenotazione = p_id_annullata;
                dataMax:= datamax - NUMTODSINTERVAL (4, 'HOUR');

                if(sysdate > datamax) then
                    gui.AggiungiPopup(false,'La prenotazione non può più essere annullata');
                else
                    gui.AggiungiPopup(true,'Prenotazione annullata con successo');
                    UPDATE Prenotazioni SET Stato = 'annullata' WHERE IDprenotazione = p_id_annullata;
                end if;
            end if;

            gui.aCapo();
            gui.aCapo();

            gui.ApriFormFiltro(u_root||'.visualizzaPrenotazioniTaxi');

            -- Campi hidden
            gui.AggiungiCampoFormHidden('text', 'p_idSess', p_idSess);
            gui.AggiungiCampoFormHidden('number', 'p_id_taxi', p_id_taxi);

            gui.AggiungiRigaTabella();
            gui.AggiungiCampoFormFiltro('number', 'p_id_prenotazione', '', 'ID', minimo => 1);
            gui.AggiungiCampoFormFiltro('text', 'p_partenza', '', 'Luogo di Partenza');
            gui.AggiungiCampoFormFiltro('date', 'p_data', '', 'Data di Partenza');
            gui.AggiungiCampoFormFiltro('time', 'p_ora', '', 'Ora di Partenza');
            gui.AggiungiCampoFormFiltro('text', 'p_arrivo', '', 'Luogo di Arrivo');

            gui.AggiungiCampoFormFiltro('submit', 'p_sub', 'F', 'Filtra');
            gui.ChiudiRigaTabella();
            gui.AggiungiRigaTabella();

            gui.AggiungiCampoFormFiltro('number', 'p_persone', '', 'Persone', minimo => 1, massimo => 8);

            gui.APRISELECTFORMFILTRO('p_modificata', 'Modificata');
            gui.AGGIUNGIOPZIONESELECT(0, false, 'non modificata');
            gui.AGGIUNGIOPZIONESELECT(1, false, 'modificata');
            gui.CHIUDISELECTFORMFILTRO;

            gui.APRISELECTFORMFILTRO('p_stato','stato');
            gui.AGGIUNGIOPZIONESELECT('', true, '');
            gui.AGGIUNGIOPZIONESELECT('accettata', false, 'accettata');
            gui.AGGIUNGIOPZIONESELECT('pendente', false, 'pendente');
            gui.AGGIUNGIOPZIONESELECT('rifiutata', false, 'rifiutata');
            gui.AGGIUNGIOPZIONESELECT('annullata', false, 'annullata');
            gui.CHIUDISELECTFORMFILTRO;

            gui.AggiungiCampoFormFiltro('number', 'p_durata', '', 'Durata', minimo => 0);

            gui.aggiungiElementoTabella();
            gui.AggiungiCampoFormFiltro('submit', 'p_sub', 'R', 'Reset');
            gui.chiudiRigaTabella();
            gui.chiudiFormFiltro();

            gui.aCapo();

            gui.ApriTabella(head);

            for x in (SELECT Prenotazioni.*
                    FROM PRENOTAZIONI
                    LEFT JOIN
                        PRENOTAZIONESTANDARD ON  (TipoTaxi='Standard' or TipoTaxi is null)
                            AND PRENOTAZIONI.IDPRENOTAZIONE = PRENOTAZIONESTANDARD.FK_PRENOTAZIONE
                    LEFT JOIN
                        PRENOTAZIONELUSSO ON (TipoTaxi='Lusso' or TipoTaxi is null)
                            AND PRENOTAZIONI.IDPRENOTAZIONE = PRENOTAZIONELUSSO.FK_PRENOTAZIONE
                    LEFT JOIN
                        PRENOTAZIONEACCESSIBILE ON (TipoTaxi='Accessibile' or TipoTaxi is null)
                            AND PRENOTAZIONI.IDPRENOTAZIONE = PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE
                    where
                        ((PRENOTAZIONESTANDARD.FK_TAXI = p_id_taxi)
                        or (PRENOTAZIONEACCESSIBILE.FK_TAXIACCESSIBILE = p_id_taxi)
                        or (PRENOTAZIONELUSSO.FK_TAXI = p_id_taxi))
                        and (Prenotazioni.IDPRENOTAZIONE = p_id_prenotazione or p_id_prenotazione is null)
                        and ((trunc(Prenotazioni.DATAORA) = to_date(p_data, 'YYYY-MM-DD')) or p_data is null)
                        and (to_char(Prenotazioni.DATAORA, 'HH24:MI') = p_ora or p_ora is null)
                        and (LOWER(replace(Prenotazioni.LUOGOPARTENZA,' ','')) LIKE LOWER(replace(('%'||p_partenza||'%'),' ','')) or p_partenza is null)
                        and (Prenotazioni.Npersone = p_persone or p_persone is null)
                        and (LOWER(replace(Prenotazioni.LUOGOARRIVO, ' ', '')) LIKE LOWER(replace(('%'||p_arrivo||'%'),' ','')) or p_arrivo is null)
                        and (Prenotazioni.STATO = p_stato or p_stato is null)
                        and (Prenotazioni.MODIFICATA = p_modificata or p_modificata is null)
                        and (Prenotazioni.DURATA = p_durata or p_durata is null)
                )
                loop
                    gui.AggiungiRigaTabella();
                    gui.AggiungiElementoTabella('' || x.IDprenotazione || '');
                    gui.AggiungiElementoTabella(x.LuogoPartenza || '');
                    gui.AggiungiElementoTabella(to_char(x.Dataora,'DD-MM-YYYY'));
                    gui.AggiungiElementoTabella((to_char(x.DataOra, 'HH24:MI')));
                    gui.AggiungiElementoTabella('' || x.LuogoArrivo || '');
                    gui.AggiungiElementoTabella('' || x.Npersone || '');

                    case x.MODIFICATA
                                when 0 then gui.AGGIUNGIELEMENTOTABELLA('No');
                                when 1 then gui.AGGIUNGIELEMENTOTABELLA('Sì');
                                end case;

                    gui.AggiungiElementoTabella('' || x.Stato || '');
                    gui.AggiungiElementoTabella('' || x.Durata || '');

                    gui.apriElementoPulsanti();
                    gui.AggiungiPulsanteModifica(u_root || '.modificaPrenotazione?p_idSess=' || p_idSess || '&p_id_prenotazione=' || x.IDprenotazione || '');
                    gui.AggiungiPulsanteCancellazione(''''|| u_root || '.visualizzaPrenotazioniTaxi' || '?p_idSess=' || p_idSess || '&p_sub=A' || '&p_id_annullata=' || x.IDprenotazione || '&p_id_taxi='|| p_id_taxi || '''');
                    gui.chiudiElementoPulsanti();

                    gui.ChiudiRigaTabella();
                end loop;

            gui.ChiudiTabella();
            gui.aCapo();

            gui.ChiudiPagina();

        end visualizzaPrenotazionitaxi;

        procedure gestireCorsaPrenotata(
            p_idSess in SESSIONICLIENTI.IDSESSIONE%TYPE default null,
            p_id_prenotazione in PRENOTAZIONI.IDprenotazione%TYPE default null,
            p_data varchar2 default null,
            p_oraPartenza varchar2 default null,
            p_partenza in PRENOTAZIONI.LuogoPartenza%TYPE default null,
            p_persone in PRENOTAZIONI.Npersone%TYPE default null,
            p_arrivo in PRENOTAZIONI.LuogoArrivo%TYPE default null,
            p_stato in PRENOTAZIONI.Stato%TYPE default null,
            p_oraArrivo in varchar2 default null,
            p_importo in CorsePrenotate.importo%TYPE default null,
            p_KM in CorsePrenotate.KM%TYPE default null,
            p_sub in varchar2 default null)

        is

            id int;
            head gui.StringArray;
            ruolo varchar(10);
            OraArrivo date;
            tariffa number(5,2);
            sconto number(5,2);
            nuovaDurata number;

        begin

            -- Controllo che si stia cercando di accedere alla procedura con i giusti permessi
            ruolo := SessionHandler.getRuolo(p_idSess);
            if ruolo <> 'Autista' or ruolo is null then
                raise NoPermessi;
            end if;

            id := SessionHandler.getIDuser(p_idSess);
            gui.ApriPagina('Gestire Corsa Prenotata',p_idSess);

            --Prendo lo sconto
            Select sum(Convenzioni.Sconto) into sconto from Convenzioni JOIN convenzioniApplicate ON Convenzioni.IDconvenzione = convenzioniApplicate.FK_Convenzione
            JOIN prenotazioni on Prenotazioni.IDprenotazione = ConvenzioniApplicate.FK_NonAnonime and Prenotazioni.IDprenotazione = p_id_prenotazione;

            if sconto is null then sconto := 0;
            end if;

            --Prendo la tariffa
            Select Tariffa into tariffa from Taxi where taxi.IDtaxi =
                ( Select Taxi.IDTaxi From Taxi
                            left join turni on  turni.FK_TAXI=taxi.IDTAXI
                            left Join TAXISTANDARD on Taxi.IDTaxi = TAXISTANDARD.FK_Taxi
                            left join TaxiAccessibile on Taxi.IDTaxi = TaxiAccessibile.FK_Taxi
                            left join TaxiLusso on Taxi.IDTaxi = TaxiLusso.FK_Taxi
                            left join PrenotazioneStandard on PrenotazioneStandard.FK_TAXI = TAXISTANDARD.FK_Taxi
                            left join PrenotazioneAccessibile on PrenotazioneAccessibile.FK_TaxiAccessibile = TaxiAccessibile.FK_Taxi
                            left join PrenotazioneLusso on PrenotazioneLusso.FK_Taxi = TaxiLusso.FK_Taxi
                            where turni.FK_AUTISTA = id and (PrenotazioneStandard.FK_Prenotazione = p_id_prenotazione or
                                                            PrenotazioneAccessibile.FK_Prenotazione = p_id_prenotazione or
                                                            PrenotazioneLusso.FK_Prenotazione = p_id_prenotazione)
                            and (sysdate between TURNI.DATAORAINIZIOEFF and TURNI.DATAORAFINE)
                        );

            if(p_sub = 'T') then

                gui.AggiungiIntestazione('Corsa terminata', 'h1');

                nuovaDurata := (TO_DATE(p_oraArrivo,'HH24:MI') - TO_DATE(p_oraPartenza,'HH24:MI'))*24*60;
                sconto := ((nuovaDurata * tariffa) * sconto) / 100;

                --Aggiorno Corse
                UPDATE CorsePrenotate Set Durata = nuovaDurata, Importo = ROUND(nuovaDurata * tariffa - sconto,2), KM = p_Km
                where CorsePrenotate.FK_Prenotazione = p_id_prenotazione;

                gui.aggiungiPopup(true,'Corsa terminata con successo');
                gui.acapo(2);

                gui.AggiungiIntestazione('Importo', 'h1');
                gui.AggiungiIntestazione(ROUND(nuovaDurata * tariffa - sconto,2) || '€', 'h3', 'text');
                gui.aCapo(3);
                gui.BottoneAggiungi('Chiudi',url => u_root || '.visPrenAssegnateTaxi' || '?p_idSess=' || p_idSess);
                gui.chiudiPagina();

                return;

            else if (p_sub is not null) then
                gui.acapo();
                gui.aggiungiPopup(false,'Errore');
                gui.acapo(4);

                gui.BottoneAggiungi('Chiudi',url => u_root || '.visPrenAssegnateTaxi' || '?p_idSess=' || p_idSess);
                gui.chiudiPagina();
                return;
                end if;
            end if;

            head := gui.StringArray('ID', 'Luogo di Partenza', 'Data di Partenza', 'Ora di Partenza', 'Passeggeri',
                                    'Luogo di Arrivo','Orario arrivo','Importo','Km',' ',' ');

            gui.AggiungiIntestazione('Corsa avviata', 'h1');

            gui.aCapo(7);

            gui.ApriFormFiltro(u_root || '.gestireCorsaPrenotata');

            for x in(SELECT Prenotazioni.*,CorsePrenotate.Passeggeri, CorsePrenotate.DataOra as Data
                    FROM Prenotazioni,CorsePrenotate
                    where
                        (Prenotazioni.IDPrenotazione = p_id_prenotazione)
                        and (Prenotazioni.IDprenotazione = CorsePrenotate.FK_Prenotazione)
                )
                loop
                    OraArrivo:= x.Data + NUMTODSINTERVAL (x.Durata, 'MINUTE');

                    sconto := ((x.Durata * tariffa) * sconto) / 100;

                    gui.AggiungiCampoFormHidden('text','p_idSess', p_idSess);
                    gui.AggiungiCampoFormHidden('number','p_id_prenotazione', p_id_prenotazione);

                    gui.AggiungiCampoFormFiltro('number', 'p_id_prenotazione', p_id_prenotazione,'ID', readonly => true);
                    gui.AggiungiCampoFormFiltro('text', 'p_partenza', x.LuogoPartenza,'Luogo di partenza', readonly => true);
                    gui.AggiungiCampoFormFiltro('date', 'p_data', to_char(x.Data, 'YYYY-MM-DD'),'Data di partenza', readonly => true);
                    gui.AggiungiCampoFormFiltro('time', 'p_oraPartenza', to_char(x.Data, 'HH24:MI'),'Ora Partenza', readonly => true);
                    gui.AggiungirigaTabella();

                    gui.AggiungiCampoFormFiltro('number', 'p_persone', x.Passeggeri,'Passeggeri', readonly => true);
                    gui.AggiungiCampoFormFiltro('text', 'p_arrivo', x.LuogoArrivo,'Luogo di arrivo');
                    gui.AggiungiCampoFormFiltro('time', 'p_oraArrivo', to_char(OraArrivo, 'HH24:MI'),'Ora di arrivo');
                    gui.AggiungiCampoFormFiltro('number', 'p_KM', 0 ,'Km', minimo => 0);

                    gui.AggiungiCampoFormFiltro('submit', 'p_sub', 'T', 'Termina');

                    gui.ChiudiRigaTabella();
                end loop;

            gui.ChiudiFormFiltro();

            gui.ChiudiPagina();

            Exception
                when NoPermessi then
                    gui.ApriPagina('Non autorizzato', p_idSess);
                    gui.AggiungiPopup(false, 'Non hai i permessi!');
                    gui.ChiudiPagina();

                when OTHERS then
                    gui.ApriPagina('Errore sconosciuto', p_idSess);
                    gui.AggiungiPopup(false, 'Errore sconosciuto');
                    gui.ChiudiPagina();

        end gestireCorsaPrenotata;

        procedure statsPrenotazioni(
            p_idSess in SESSIONICLIENTI.IDSESSIONE%TYPE default null,
            p_dataInizio varchar2 default null,
            p_dataFine varchar2 default null,
            p_partenza in PRENOTAZIONI.LuogoPartenza%TYPE default null,
            p_persone in PRENOTAZIONI.Npersone%TYPE default null,
            p_arrivo in PRENOTAZIONI.LuogoArrivo%TYPE default null,
            p_stato in PRENOTAZIONI.Stato%TYPE default null,
            p_durata in PRENOTAZIONI.Durata%TYPE default null,
            p_modificata in PRENOTAZIONI.Modificata%TYPE default null,
            p_categoria in varchar2 default null,
            p_tipologia in varchar2 default null,
            p_sub in varchar2 default null)
        is
            head gui.StringArray;
            ruolo varchar(10);
            tot int;
            giorno date;
            partenza varchar2(100);
            arrivo varchar2(100);
            passeggeri number;
            stato varchar2(20);
            nStandard number;
            nAccessibili number;
            nLusso number;
            nAnonime number;
            nTelefoniche number;
            nOnline number;
        begin
            -- Controllo che si stia cercando di accedere alla procedura con i giusti permessi
            ruolo := SessionHandler.getRuolo(p_idSess);
            if ruolo <> 'Manager' or ruolo is null then
                raise NoPermessi;
            end if;

            --Reset Filtro
            if(p_sub = 'R') then gui.Reindirizza(u_root || '.statsPrenotazioni' || '?p_idSess=' || p_idSess);
            end if;

            head := gui.StringArray('Prenotazioni totali', 'Periodo', 'Standard', 'Accessibile', 'Lusso', 'Anonima', 'Telefonica', 'Online');

            gui.ApriPagina('Statistiche Prenotazioni',p_idSess);
            gui.AggiungiIntestazione('Prenotazioni', 'h1');

            gui.aCapo(2);

            --Filtro
            gui.ApriFormFiltro(u_root||'.statsPrenotazioni');

            -- Campi hidden
            gui.AggiungiCampoFormHidden('text', 'p_idSess', p_idSess);

            gui.AggiungiRigaTabella();
            gui.AggiungiCampoFormFiltro('date', 'p_dataInizio', p_dataInizio, 'Data di inizio');
            gui.AggiungiCampoFormFiltro('date', 'p_dataFine', p_dataFine, 'Data di fine');
            gui.AggiungiCampoFormFiltro('number', 'p_persone', p_persone, 'Persone', minimo => 1, massimo => 8);

            gui.APRISELECTFORMFILTRO('p_modificata', 'Modificata');
            gui.AGGIUNGIOPZIONESELECT(0, p_modificata = 0, 'non modificata');
            gui.AGGIUNGIOPZIONESELECT(1, p_modificata = 1, 'modificata');
            gui.CHIUDISELECTFORMFILTRO;

            gui.APRISELECTFORMFILTRO('p_categoria','Categoria');
            gui.AGGIUNGIOPZIONESELECT('Standard', p_categoria = 'Standard', 'Standard');
            gui.AGGIUNGIOPZIONESELECT('Accessibile', p_categoria = 'Accessibile', 'Accessibile');
            gui.AGGIUNGIOPZIONESELECT('Lusso', p_categoria = 'Lusso', 'Lusso');
            gui.CHIUDISELECTFORMFILTRO;

            gui.AggiungiCampoFormFiltro('submit', 'p_sub', 'F', 'Filtra');
            gui.ChiudiRigaTabella();
            gui.AggiungiRigaTabella();

            gui.APRISELECTFORMFILTRO('p_stato','stato');
            gui.AGGIUNGIOPZIONESELECT('accettata', p_stato = 'accettata', 'accettata');
            gui.AGGIUNGIOPZIONESELECT('pendente', p_stato = 'pendente', 'pendente');
            gui.AGGIUNGIOPZIONESELECT('rifiutata', p_stato = 'rifiutata', 'rifiutata');
            gui.AGGIUNGIOPZIONESELECT('annullata', p_stato = 'annullata', 'annullata');
            gui.CHIUDISELECTFORMFILTRO;

            gui.AggiungiCampoFormFiltro('number', 'p_durata', p_durata, 'Durata', minimo => 0);

            gui.AggiungiCampoFormFiltro('text', 'p_partenza', p_partenza, 'Luogo di partenza');
            gui.AggiungiCampoFormFiltro('text', 'p_arrivo', p_arrivo, 'Luogo di arrivo');

            gui.APRISELECTFORMFILTRO('p_tipologia','Tipologia');
            gui.AGGIUNGIOPZIONESELECT('Anonima', p_tipologia = 'Anonima', 'Anonima');
            gui.AGGIUNGIOPZIONESELECT('Telefonica', p_tipologia = 'Telefonica', 'Telefonica');
            gui.AGGIUNGIOPZIONESELECT('Online', p_tipologia = 'Online', 'Online');
            gui.CHIUDISELECTFORMFILTRO;

            gui.AggiungiCampoFormFiltro('submit', 'p_sub', 'R', 'Reset');
            gui.chiudiRigaTabella();
            gui.chiudiFormFiltro();

            Select count(*) into tot from Prenotazioni;

            gui.aCapo();

            --Prima tabella
            gui.ApriTabella(head);

            for x in (SELECT count(*) as Totali,
                        count(PRENOTAZIONESTANDARD.FK_PRENOTAZIONE) as Standard,
                        count(PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE) as Accessibile,
                        count(PRENOTAZIONELusso.FK_PRENOTAZIONE) as Lusso,
                        count(ANONIMETELEFONICHE.FK_PRENOTAZIONE) as Anonime,
                        count(NONANONIME.FK_PRENOTAZIONE) as NonAnonime,
                        count(NONANONIME.FK_OPERATORE) as Telefoniche
                    FROM PRENOTAZIONI
                    LEFT JOIN
                        PRENOTAZIONESTANDARD ON  PRENOTAZIONI.IDPRENOTAZIONE = PRENOTAZIONESTANDARD.FK_PRENOTAZIONE
                    LEFT JOIN
                        PRENOTAZIONELUSSO ON PRENOTAZIONI.IDPRENOTAZIONE = PRENOTAZIONELUSSO.FK_PRENOTAZIONE
                    LEFT JOIN
                        PRENOTAZIONEACCESSIBILE ON PRENOTAZIONI.IDPRENOTAZIONE = PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE
                    LEFT JOIN
                        ANONIMETELEFONICHE ON PRENOTAZIONI.IDPRENOTAZIONE = ANONIMETELEFONICHE.FK_PRENOTAZIONE
                    LEFT JOIN
                        NONANONIME ON PRENOTAZIONI.IDPRENOTAZIONE = NONANONIME.FK_PRENOTAZIONE
                    where
                        ((trunc(Prenotazioni.DATAORA) >= to_date(p_dataInizio, 'YYYY-MM-DD')) or p_dataInizio is null)
                        and ((trunc(Prenotazioni.DATAORA) <= to_date(p_dataFine, 'YYYY-MM-DD')) or p_dataFine is null)
                        and (LOWER(replace(Prenotazioni.LUOGOPARTENZA,' ','')) LIKE LOWER(replace(('%'||p_partenza||'%'),' ','')) or p_partenza is null)
                        and (Prenotazioni.Npersone = p_persone or p_persone is null)
                        and (LOWER(replace(Prenotazioni.LUOGOARRIVO, ' ', '')) LIKE LOWER(replace(('%'||p_arrivo||'%'),' ','')) or p_arrivo is null)
                        and (Prenotazioni.STATO = p_stato or p_stato is null)
                        and (Prenotazioni.MODIFICATA = p_modificata or p_modificata is null)
                        and (Prenotazioni.DURATA = p_durata or p_durata is null)
                        and ((p_categoria = 'Standard' and PrenotazioneStandard.FK_Prenotazione is not null) or
                            (p_categoria = 'Accessibile' and PrenotazioneAccessibile.FK_Prenotazione is not null) or
                            (p_categoria = 'Lusso' and PrenotazioneLusso.FK_Prenotazione is not null)
                            or p_categoria is null)
                        and ((p_tipologia = 'Anonima' and AnonimeTelefoniche.FK_Prenotazione is not null) or
                            (p_tipologia = 'Telefonica' and NonAnonime.Tipo = 1) or
                            (p_tipologia = 'Online' and NonAnonime.Tipo = 0)
                            or p_tipologia is null)
                )
                loop
                    gui.AggiungiRigaTabella();

                    gui.AggiungiElementoTabella('' || x.Totali || '');

                    gui.AggiungiElementoTabella('' || to_char(to_date(p_dataInizio,'YYYY-MM-DD'),'DD/MM/YY') || ' - ' || to_char(to_date(p_dataFine,'YYYY-MM-DD'),'DD/MM/YY') || '');
                    gui.AggiungiElementoTabella('' || x.Standard || '');
                    gui.AggiungiElementoTabella('' || x.Accessibile || '');
                    gui.AggiungiElementoTabella('' || x.Lusso || '');
                    gui.AggiungiElementoTabella('' || x.Anonime || '');
                    gui.AggiungiElementoTabella('' || x.Telefoniche || '');
                    gui.AggiungiElementoTabella('' || x.NonAnonime - x.Telefoniche || '');

                    nStandard := x.Standard;
                    nAccessibili := x.Accessibile;
                    nLusso := x.Lusso;
                    nAnonime := x.Anonime;
                    nTelefoniche := x.Telefoniche;
                    nOnline := x.NonAnonime - x.Telefoniche;



                    gui.ChiudiRigaTabella();
                    gui.AggiungiRigaTabella();

                    gui.AggiungiElementoTabella('' || round(x.Totali*100/tot,1) || '%');
                    gui.AggiungiElementoTabella();
                    gui.AggiungiElementoTabella('' || round(x.Standard*100/x.Totali,1) || '%');
                    gui.AggiungiElementoTabella('' || round(x.Accessibile*100/x.Totali,1) || '%');
                    gui.AggiungiElementoTabella('' || round(x.Lusso*100/x.Totali,1) || '%');
                    gui.AggiungiElementoTabella('' || round(x.Anonime*100/x.Totali,1) || '%');
                    gui.AggiungiElementoTabella('' || round(x.Telefoniche*100/x.Totali,1) || '%');
                    gui.AggiungiElementoTabella('' || round((x.NonAnonime-x.Telefoniche)*100/x.Totali,1) || '%');

                    gui.ChiudiRigaTabella();
                end loop;


            gui.ChiudiTabella();

            --Seconda tabella
            gui.aCapo();
            gui.AggiungiIntestazione('Dati con il maggior numero di prenotazioni', 'h1');
            gui.aCapo(2);
            head := gui.StringArray('Giorno', 'Luogo di partenza', 'Luogo di Arrivo', 'Passeggeri', 'Stato');

            --Giorno con più prenotazioni
            Select TRUNC(DataOra,'DDD') as Data into giorno  From Prenotazioni Group by TRUNC(DataOra,'DDD')
            Having count(*) = (Select max(c) from (
                Select count(*) as c, TRUNC(DataOra,'DDD') as Data
                From Prenotazioni group by TRUNC(DataOra,'DDD'))) fetch first 1 row only;

            --Luogo di partenza
            Select LuogoPartenza into partenza  From Prenotazioni Group by LuogoPartenza
            Having count(*) = (Select max(c) from (
                Select count(*) as c, LuogoPartenza
                From Prenotazioni group by LuogoPartenza)) fetch first 1 row only;

            --Luogo di arrivo
            Select LuogoArrivo into arrivo  From Prenotazioni Group by LuogoArrivo
            Having count(*) = (Select max(c) from (
                Select count(*) as c, LuogoArrivo
                From Prenotazioni group by LuogoArrivo)) fetch first 1 row only;

            --Passeggeri
            Select Npersone into passeggeri  From Prenotazioni Group by Npersone
            Having count(*) = (Select max(c) from (
                Select count(*) as c, Npersone
                From Prenotazioni group by Npersone)) fetch first 1 row only;

            --Stato
            Select Stato into stato  From Prenotazioni Group by Stato
            Having count(*) = (Select max(c) from (
                Select count(*) as c, Stato
                From Prenotazioni group by Stato)) fetch first 1 row only;

            gui.ApriTabella(head, '1');

            gui.AggiungiRigaTabella();

            gui.AggiungiElementoTabella('' || giorno || '');
            gui.AggiungiElementoTabella('' || partenza || '');
            gui.AggiungiElementoTabella('' || arrivo || '');
            gui.AggiungiElementoTabella('' || passeggeri || '');
            gui.AggiungiElementoTabella('' || stato || '');

            gui.chiudiRigaTabella();
            gui.chiudiTabella('1');

            gui.aCapo(5);

            gui.apriDiv(classe => 'chart-row');

            gui.aggiungiChart('grafico', '{
                    type: "pie",
                    data: {
                        labels: [
                            "Standard",
                            "Accessibile",
                            "Lusso"
                        ],
                        datasets: [
                            {
                                label: "",
                                data: ['|| nStandard ||','|| nAccessibili ||','|| nLusso ||'],
                                borderColor: "rgb(0, 0, 0, 0.5)",
                                backgroundColor: [
                                                "rgb(255, 0, 0)",

                                                "rgb(0, 255, 0)",


                                                "rgb(0, 0, 255)"]
                            }
                        ]
                    },
                    options: {
                        responsive: true,
                        plugins: {
                            legend: {
                                position: "top",
                            },
                            title: {
                                display: true,
                                text: "Prenotazioni"
                            }
                        },
                    },
                }'
            );

            gui.aggiungiChart('grafico ||', '{
                    type: "pie",
                    data: {
                        labels: [
                            "Anonima",
                            "Telefonica",
                            "Online"
                        ],
                        datasets: [
                            {
                                label: "",
                                data: ['|| nAnonime ||','|| nTelefoniche ||','|| nOnline ||'],
                                borderColor: "rgb(0, 0, 0, 0.5)",
                                backgroundColor: [
                                                "rgb(255, 188, 0)",

                                                "rgb(188, 255, 0)",


                                                "rgb(0, 188, 255)"]
                            }
                        ]
                    },
                    options: {
                        responsive: true,
                        plugins: {
                            legend: {
                                position: "top",
                            },
                            title: {
                                display: true,
                                text: "Prenotazioni"
                            }
                        },
                    },
                }'
            );

            gui.chiudidiv();

            gui.acapo(2);

            gui.ChiudiPagina('
                    const chartRows = document.getElementsByClassName("chart-row");

                    for (chartRow of chartRows){
                        chartRow.querySelectorAll("div").forEach( chart => {
                            chart.style.height = "50vh";
                        });

                        chartRow.style.display = "flex";
                        chartRow.style.justifyContent = "center";
                        chartRow.style.alignItems = "center";
                    }
            ');

            Exception
                when NoPermessi then
                    gui.ApriPagina('Non autorizzato', p_idSess);
                    gui.AggiungiPopup(false, 'Non hai i permessi!');
                    gui.ChiudiPagina();

                when OTHERS then
                    gui.ApriPagina('Errore sconosciuto', p_idSess);
                    gui.AggiungiPopup(false, 'Errore sconosciuto');
                    gui.ChiudiPagina();

        end statsPrenotazioni;

        procedure statsCorsePrenotate(
            p_idSess in SESSIONICLIENTI.IDSESSIONE%TYPE default null,
            p_dataInizio varchar2 default null,
            p_dataFine varchar2 default null,
            p_partenza in PRENOTAZIONI.LuogoPartenza%TYPE default null,
            p_persone in PRENOTAZIONI.Npersone%TYPE default null,
            p_arrivo in PRENOTAZIONI.LuogoArrivo%TYPE default null,
            p_durata in PRENOTAZIONI.Durata%TYPE default null,
            p_categoria in varchar2 default null,
            p_tipologia in varchar2 default null,
            p_sub in varchar2 default null)
        is
            head gui.StringArray;
            ruolo varchar(10);
            tot int;
            durata number(5,2);
            importo number(5,2);
            km number(5,2);
            passeggeri number(1,0);
        begin
            -- Controllo che si stia cercando di accedere alla procedura con i giusti permessi
            ruolo := SessionHandler.getRuolo(p_idSess);
            if ruolo <> 'Manager' or ruolo is null then
                raise NoPermessi;
            end if;

            --Reset Filtro
            if(p_sub = 'R') then gui.Reindirizza(u_root || '.statsCorsePrenotate' || '?p_idSess=' || p_idSess);
            end if;

            head := gui.StringArray('Corse totali', 'Periodo', 'Standard', 'Accessibile', 'Lusso', 'Anonima', 'Telefonica', 'Online');

            gui.ApriPagina('Statistiche Corse Prenotate',p_idSess);
            gui.AggiungiIntestazione('Corse Prenotate', 'h1');

            gui.aCapo(2);

            --Filtro
            gui.ApriFormFiltro(u_root||'.statsCorsePrenotate');

            -- Campi hidden
            gui.AggiungiCampoFormHidden('text', 'p_idSess', p_idSess);

            gui.AggiungiRigaTabella();
            gui.AggiungiCampoFormFiltro('date', 'p_dataInizio', p_dataInizio, 'Data di inizio');
            gui.AggiungiCampoFormFiltro('date', 'p_dataFine', p_dataFine, 'Data di fine');
            gui.AggiungiCampoFormFiltro('number', 'p_persone', p_persone, 'Persone', minimo => 1, massimo => 8);

            gui.APRISELECTFORMFILTRO('p_categoria','Categoria');
            gui.AGGIUNGIOPZIONESELECT('Standard', p_categoria = 'Standard', 'Standard');
            gui.AGGIUNGIOPZIONESELECT('Accessibile', p_categoria = 'Accessibile', 'Accessibile');
            gui.AGGIUNGIOPZIONESELECT('Lusso', p_categoria = 'Lusso', 'Lusso');
            gui.CHIUDISELECTFORMFILTRO;

            gui.AggiungiCampoFormFiltro('submit', 'p_sub', 'F', 'Filtra');
            gui.ChiudiRigaTabella();
            gui.AggiungiRigaTabella();

            gui.AggiungiCampoFormFiltro('number', 'p_durata', p_durata, 'Durata', minimo => 0);

            gui.AggiungiCampoFormFiltro('text', 'p_partenza', p_partenza, 'Luogo di partenza');
            gui.AggiungiCampoFormFiltro('text', 'p_arrivo', p_arrivo, 'Luogo di arrivo');

            gui.APRISELECTFORMFILTRO('p_tipologia','Tipologia');
            gui.AGGIUNGIOPZIONESELECT('Anonima', p_tipologia = 'Anonima', 'Anonima');
            gui.AGGIUNGIOPZIONESELECT('Telefonica', p_tipologia = 'Telefonica', 'Telefonica');
            gui.AGGIUNGIOPZIONESELECT('Online', p_tipologia = 'Online', 'Online');
            gui.CHIUDISELECTFORMFILTRO;

            gui.AggiungiCampoFormFiltro('submit', 'p_sub', 'R', 'Reset');
            gui.chiudiRigaTabella();
            gui.chiudiFormFiltro();

            Select count(*) into tot from CorsePrenotate;

            gui.aCapo();

            --Prima tabella
            gui.ApriTabella(head);

            for x in (SELECT count(*) as Totali,
                        count(PRENOTAZIONESTANDARD.FK_PRENOTAZIONE) as Standard,
                        count(PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE) as Accessibile,
                        count(PRENOTAZIONELusso.FK_PRENOTAZIONE) as Lusso,
                        count(ANONIMETELEFONICHE.FK_PRENOTAZIONE) as Anonime,
                        count(NONANONIME.FK_PRENOTAZIONE) as NonAnonime,
                        count(NONANONIME.FK_OPERATORE) as Telefoniche,
                        sum(CORSEPRENOTATE.PASSEGGERI) as totPasseggeri,
                        sum(CORSEPRENOTATE.DURATA) as totDurata,
                        sum(CORSEPRENOTATE.IMPORTO) as totImporto,
                        sum(CORSEPRENOTATE.KM) as totKm
                    FROM CorsePrenotate
                    LEFT JOIN
                        PRENOTAZIONI ON PRENOTAZIONI.IDprenotazione = CORSEPRENOTATE.FK_PRENOTAZIONE
                    LEFT JOIN
                        PRENOTAZIONESTANDARD ON  PRENOTAZIONI.IDPRENOTAZIONE = PRENOTAZIONESTANDARD.FK_PRENOTAZIONE
                    LEFT JOIN
                        PRENOTAZIONELUSSO ON PRENOTAZIONI.IDPRENOTAZIONE = PRENOTAZIONELUSSO.FK_PRENOTAZIONE
                    LEFT JOIN
                        PRENOTAZIONEACCESSIBILE ON PRENOTAZIONI.IDPRENOTAZIONE = PRENOTAZIONEACCESSIBILE.FK_PRENOTAZIONE
                    LEFT JOIN
                        ANONIMETELEFONICHE ON PRENOTAZIONI.IDPRENOTAZIONE = ANONIMETELEFONICHE.FK_PRENOTAZIONE
                    LEFT JOIN
                        NONANONIME ON PRENOTAZIONI.IDPRENOTAZIONE = NONANONIME.FK_PRENOTAZIONE
                    where
                        ((trunc(Prenotazioni.DATAORA) >= to_date(p_dataInizio, 'YYYY-MM-DD')) or p_dataInizio is null)
                        and ((trunc(Prenotazioni.DATAORA) <= to_date(p_dataFine, 'YYYY-MM-DD')) or p_dataFine is null)
                        and (LOWER(replace(Prenotazioni.LUOGOPARTENZA,' ','')) LIKE LOWER(replace(('%'||p_partenza||'%'),' ','')) or p_partenza is null)
                        and (Prenotazioni.Npersone = p_persone or p_persone is null)
                        and (LOWER(replace(Prenotazioni.LUOGOARRIVO, ' ', '')) LIKE LOWER(replace(('%'||p_arrivo||'%'),' ','')) or p_arrivo is null)
                        and (Prenotazioni.DURATA = p_durata or p_durata is null)
                        and ((p_categoria = 'Standard' and PrenotazioneStandard.FK_Prenotazione is not null) or
                            (p_categoria = 'Accessibile' and PrenotazioneAccessibile.FK_Prenotazione is not null) or
                            (p_categoria = 'Lusso' and PrenotazioneLusso.FK_Prenotazione is not null)
                            or p_categoria is null)
                        and ((p_tipologia = 'Anonima' and AnonimeTelefoniche.FK_Prenotazione is not null) or
                            (p_tipologia = 'Telefonica' and NonAnonime.Tipo = 1) or
                            (p_tipologia = 'Online' and NonAnonime.Tipo = 0)
                            or p_tipologia is null)
                )
                loop

                    passeggeri := x.totPasseggeri / x.Totali;
                    durata := x.totDurata / x.Totali;
                    importo := x.totImporto / x.Totali;
                    km := x.totKm / x.Totali;

                    gui.aggiungiChart('grafico', '{
                                type: "bar",
                                data: {
                                    labels: [
                                        "Standard",
                                        "Accessibile",
                                        "Lusso",
                                        "Anonime",
                                        "Telefoniche",
                                        "Online"
                                    ],
                                    datasets: [
                                        {
                                            label: "Tipologia",
                                            data: ['|| x.Standard ||',' || x.Accessibile ||','|| x.Lusso ||',' || x.Anonime||','||x.Telefoniche||','||(x.NonAnonime-x.Telefoniche)||'],
                                            borderColor: "rgb(0, 0, 0, 0.5)",
                                            backgroundColor: [
                                                            "rgb(255, 0, 0)",
                                                            "rgb(0, 255, 0)",
                                                            "rgb(0, 0, 255)",
                                                            "rgb(255, 255, 0)",
                                                            "rgb(0, 255, 255)",
                                                            "rgb(255, 255, 255)"
                                                            ]
                                        }
                                    ]
                                },
                                options: {
                                    responsive: true,
                                    plugins: {
                                        legend: {
                                            position: "none",
                                        },
                                        title: {
                                            display: true,
                                            text: "Corse Prenotate"
                                        }
                                    },
                                },
                            }'
                        );

                    gui.aCapo(3);

                    gui.AggiungiRigaTabella();

                    gui.AggiungiElementoTabella('' || round(x.Totali*100/tot,1) || '%');

                    gui.AggiungiElementoTabella('' || to_char(to_date(p_dataInizio,'YYYY-MM-DD'),'DD/MM/YY') || ' - ' || to_char(to_date(p_dataFine,'YYYY-MM-DD'),'DD/MM/YY') || '');

                    gui.AggiungiElementoTabella('' || round(x.Standard*100/x.Totali,1) || '%');
                    gui.AggiungiElementoTabella('' || round(x.Accessibile*100/x.Totali,1) || '%');
                    gui.AggiungiElementoTabella('' || round(x.Lusso*100/x.Totali,1) || '%');
                    gui.AggiungiElementoTabella('' || round(x.Anonime*100/x.Totali,1) || '%');
                    gui.AggiungiElementoTabella('' || round(x.Telefoniche*100/x.Totali,1) || '%');
                    gui.AggiungiElementoTabella('' || round((x.NonAnonime-x.Telefoniche)*100/x.Totali,1) || '%');

                    gui.ChiudiRigaTabella();
                end loop;


            gui.ChiudiTabella();

            --Seconda tabella
            gui.aCapo(3);
            head := gui.StringArray('Media Durata','Media Passeggeri','Media Importo','Media Chilometri');

            gui.ApriTabella(head,'1');

            gui.AggiungiRigaTabella();

            gui.AggiungiElementoTabella('' || durata || '');
            gui.AggiungiElementoTabella('' || passeggeri || '');
            gui.AggiungiElementoTabella('' || importo || '');
            gui.AggiungiElementoTabella('' || km || '');

            gui.chiudiRigaTabella();

            gui.ChiudiTabella('1');

            gui.aCapo(2);

            gui.ChiudiPagina();

            Exception
                when NoPermessi then
                    gui.ApriPagina('Non autorizzato', p_idSess);
                    gui.AggiungiPopup(false, 'Non hai i permessi!');
                    gui.ChiudiPagina();
                when OTHERS then
                    gui.ApriPagina('Errore sconosciuto', p_idSess);
                    gui.AggiungiPopup(false, 'Errore sconosciuto');

            gui.ChiudiPagina();
        end statsCorsePrenotate;

    -----------------------------------Chine-----------------------------------------

    procedure mvp(
        p_idSess SESSIONIDIPENDENTI.IDSESSIONE%TYPE default null,
        p_autista AUTISTI.FK_DIPENDENTE%TYPE default null,
        p_operatore OPERATORI.FK_DIPENDENTE%TYPE default null,
        p_cliente CLIENTI.IDCLIENTE%TYPE default null,
        p_id in PRENOTAZIONI.IDprenotazione%TYPE default null,
        p_data_min varchar2 default null,
        p_data_max varchar2 default null,
        p_ora_min varchar2 default null,
        p_ora_max varchar2 default null,
        p_partenza in PRENOTAZIONI.LuogoPartenza%TYPE default null,
        p_persone in PRENOTAZIONI.Npersone%TYPE default null,
        p_arrivo in PRENOTAZIONI.LuogoArrivo%TYPE default null,
        p_stato in PRENOTAZIONI.Stato%TYPE default null,
        p_durata in PRENOTAZIONI.Durata%TYPE default null,
        p_modificata in PRENOTAZIONI.Modificata%TYPE default null,
        p_tipo in NONANONIME.TIPO%TYPE default null,
        p_categoria in varchar2 default null
    ) is
        nome             DIPENDENTI.NOME%TYPE;
        cognome          DIPENDENTI.COGNOME%TYPE;
        headAutisti      gui.StringArray;
        headOperatori    gui.STRINGARRAY;
        headClienti      gui.STRINGARRAY;
        headPrenotazioni gui.STRINGARRAY;
        passeggeriAccessibili PRENOTAZIONEACCESSIBILE.NPERSONEDISABILI%TYPE default 0;
        lusso PRENOTAZIONELUSSO.FK_PRENOTAZIONE%TYPE default null;
        optionals NUMBER;
    begin
        if not SESSIONHANDLER.CHECKRUOLO(p_idSess, 'Manager') then
            RAISE NoPermessi;
        end if;

        if p_autista is null and p_operatore is null and p_cliente is null then

            headAutisti := gui.STRINGARRAY('Matricola', 'Nome', 'Cognome', 'Telefono', 'Neopatentato', ' ');
            headOperatori := gui.STRINGARRAY('Matricola', 'Nome', 'Cognome', 'Telefono', ' ');
            headClienti := gui.STRINGARRAY('ID', 'Nome', 'Cognome', 'Stato', ' ');

            -- pagina di selezione
            gui.APRIPAGINA('Selezione', p_idSess);

            -- autisti
            gui.AGGIUNGIINTESTAZIONE('Autisti');
            gui.ACAPO();

            gui.APRITABELLA(headAutisti, 'autisti');

            for autista in (select D.MATRICOLA,
                                   D.NOME,
                                   D.COGNOME,
                                   D.NTELEFONO,
                                   months_between(current_date, A.DATAPATENTE) as NEOPATENTATO
                            from DIPENDENTI D
                                     join AUTISTI A on D.MATRICOLA = A.FK_DIPENDENTE)
                loop
                    gui.AGGIUNGIRIGATABELLA();

                    gui.AGGIUNGIELEMENTOTABELLA(autista.MATRICOLA);
                    gui.AGGIUNGIELEMENTOTABELLA(autista.NOME);
                    gui.AGGIUNGIELEMENTOTABELLA(autista.COGNOME);
                    gui.AGGIUNGIELEMENTOTABELLA(autista.NTELEFONO);

                    if autista.NEOPATENTATO < 12 then
                        gui.AGGIUNGIELEMENTOTABELLA('Sì');
                    else
                        gui.AGGIUNGIELEMENTOTABELLA('No');
                    end if;

                    gui.AGGIUNGIBOTTONETABELLA('Visualizza',
                                               url => U_ROOT || '.mvp?p_idSess=' || p_idSess || '&p_autista=' ||
                                                      autista.MATRICOLA);

                    gui.CHIUDIRIGATABELLA();
                end loop;

            gui.CHIUDITABELLA('autisti');
            gui.ACAPO();

            -- operatori
            gui.AGGIUNGIINTESTAZIONE('Operatori');
            gui.ACAPO();

            gui.APRITABELLA(headOperatori, 'operatori');
            for operatore in (select D.MATRICOLA,
                                     D.NOME,
                                     D.COGNOME,
                                     D.NTELEFONO
                              from DIPENDENTI D
                                       join OPERATORI O on D.MATRICOLA = O.FK_DIPENDENTE)
                loop
                    gui.AGGIUNGIRIGATABELLA();

                    gui.AGGIUNGIELEMENTOTABELLA(operatore.MATRICOLA);
                    gui.AGGIUNGIELEMENTOTABELLA(operatore.NOME);
                    gui.AGGIUNGIELEMENTOTABELLA(operatore.COGNOME);
                    gui.AGGIUNGIELEMENTOTABELLA(operatore.NTELEFONO);

                    gui.AGGIUNGIBOTTONETABELLA('Visualizza',
                                               url => U_ROOT || '.mvp?p_idSess=' || p_idSess || '&p_operatore=' ||
                                                      operatore.MATRICOLA);

                    gui.CHIUDIRIGATABELLA();
                end loop;
            gui.CHIUDITABELLA('operatori');
            gui.ACAPO();

            -- clienti
            gui.AGGIUNGIINTESTAZIONE('Clienti');
            gui.ACAPO();

            gui.APRITABELLA(headClienti, 'clienti');
            for cliente in (select C.IDCLIENTE,
                                   C.NOME,
                                   C.COGNOME,
                                   C.STATO
                            from CLIENTI C)
                loop
                    gui.AGGIUNGIRIGATABELLA();

                    gui.AGGIUNGIELEMENTOTABELLA(cliente.IDCLIENTE);
                    gui.AGGIUNGIELEMENTOTABELLA(cliente.NOME);
                    gui.AGGIUNGIELEMENTOTABELLA(cliente.COGNOME);
                    gui.AGGIUNGIELEMENTOTABELLA(cliente.STATO);

                    gui.AGGIUNGIBOTTONETABELLA('Visualizza',
                                               url => U_ROOT || '.mvp?p_idSess=' || p_idSess || '&p_cliente=' ||
                                                      cliente.IDCLIENTE);

                    gui.CHIUDIRIGATABELLA();
                end loop;
            gui.CHIUDITABELLA('clienti');
            gui.ACAPO();

        else
            headPrenotazioni := gui.StringArray('Codice', 'Luogo di Partenza', 'Data di Partenza', 'Ora di Partenza',
                                                'Luogo di Arrivo',
                                               -- 'Persone', 'Modificata', 'Stato', 'Durata');
            ' ');

            -- lista prenotazioni
            if (p_autista is not null) then
                -- prenotazioni autisti
                begin
                    select D.NOME, D.COGNOME
                    into nome, cognome
                    from AUTISTI A
                    left join DIPENDENTI D on D.MATRICOLA = A.FK_DIPENDENTE
                    where (A.FK_DIPENDENTE = p_autista);
                exception
                    when others then
                        gui.APRIPAGINA('Errore', p_idSess);
                        gui.AGGIUNGIPOPUP(false, 'Autista inesistente!');
                        gui.CHIUDIPAGINA();
                        return;
                end;

                gui.APRIPAGINA('Prenotazioni | ' || nome || ' ' || cognome, p_idSess);
                gui.AGGIUNGIINTESTAZIONE('Prenotazioni di ' || nome || ' ' || cognome);
                gui.ACAPO();

                -- filtro
                gui.ApriFormFiltro(u_root || '.mvp');
                gui.AggiungiCampoFormFiltro('number', 'p_id', p_id, 'Codice', minimo=>0);
                gui.AggiungiCampoFormFiltro('text', 'p_partenza', p_partenza, 'Luogo di Partenza');
                gui.AggiungiCampoFormFiltro('text', 'p_arrivo', p_arrivo, 'Luogo di Arrivo');
                gui.AggiungiCampoFormFiltro('number', 'p_durata', p_durata, 'Durata');

                gui.AGGIUNGIRIGATABELLA();

                gui.AggiungiCampoFormFiltro('date', 'p_data_min', p_data_min, 'a partire da');
                gui.AggiungiCampoFormFiltro('date', 'p_data_max', p_data_max, 'fino a');
                gui.AggiungiCampoFormFiltro('time', 'p_ora_min', p_ora_min, 'a partire da');
                gui.AggiungiCampoFormFiltro('time', 'p_ora_max', p_ora_max, 'fino a');

                gui.AGGIUNGIRIGATABELLA();
                gui.AggiungiCampoFormFiltro('number', 'p_durata', p_durata, 'Durata');
                gui.AggiungiCampoFormFiltro('number', 'p_persone', p_persone, 'Persone');
                gui.APRISELECTFORMFILTRO('p_modificata', 'modificata');
                gui.AGGIUNGIOPZIONESELECT(p_modificata, true, 'modificata: ' || case
                                                                                    when p_modificata = 0 then 'no'
                                                                                    when p_modificata = 1 then 'si'
                                                                                    ELSE '' END);
                gui.AGGIUNGIOPZIONESELECT(0, false, 'non modificata');
                gui.AGGIUNGIOPZIONESELECT(1, false, 'modificata');
                gui.AGGIUNGIOPZIONESELECT(NULL, false, 'ANNULLA SELEZIONE');
                gui.CHIUDISELECTFORMFILTRO;

                gui.APRISELECTFORMFILTRO('p_stato', 'stato');
                gui.AGGIUNGIOPZIONESELECT(p_stato, true, 'stato: ' || p_stato);
                gui.AGGIUNGIOPZIONESELECT('accettata', false, 'accettata');
                gui.AGGIUNGIOPZIONESELECT('pendente', false, 'pendente');
                gui.AGGIUNGIOPZIONESELECT('rifiutata', false, 'rifiutata');
                gui.AGGIUNGIOPZIONESELECT('annullata', false, 'annullata');
                gui.AGGIUNGIOPZIONESELECT(NULL, false, 'ANNULLA SELEZIONE');
                gui.CHIUDISELECTFORMFILTRO;

                gui.AGGIUNGIRIGATABELLA();

                gui.APRISELECTFORMFILTRO('p_categoria', 'categoria');
                gui.AGGIUNGIOPZIONESELECT(p_categoria, true, 'categoria: ' || p_categoria);
                gui.AGGIUNGIOPZIONESELECT('standard', false, 'standard');
                gui.AGGIUNGIOPZIONESELECT('lusso', false, 'lusso');
                gui.AGGIUNGIOPZIONESELECT('accessibili', false, 'accessibili');
                gui.AGGIUNGIOPZIONESELECT(NULL, false, 'ANNULLA SELEZIONE');
                gui.CHIUDISELECTFORMFILTRO;

                gui.AGGIUNGICAMPOFORMHIDDEN('text', 'p_idSess', p_idSess);
                gui.AGGIUNGICAMPOFORMHIDDEN('number', 'p_autista', p_autista);

                gui.AggiungiCampoFormFiltro('submit', '', '', 'filtra');
                gui.chiudiFormFiltro();
                gui.ACAPO();

                -- prenotazioni
                gui.APRITABELLA(headPrenotazioni);

                for prenotazione in (select *
                                     from PRENOTAZIONI P
                                              LEFT JOIN PRENOTAZIONESTANDARD PS ON P.IDPRENOTAZIONE = PS.FK_PRENOTAZIONE
                                              LEFT JOIN PRENOTAZIONEACCESSIBILE PA ON P.IDPRENOTAZIONE = PA.FK_PRENOTAZIONE
                                              LEFT JOIN PRENOTAZIONELUSSO PL ON P.IDPRENOTAZIONE = PL.FK_PRENOTAZIONE
                                              RIGHT JOIN TURNI T
                                                         ON (PS.FK_TAXI = T.FK_TAXI OR
                                                             PA.FK_TAXIACCESSIBILE = T.FK_TAXI OR
                                                             PL.FK_TAXI = T.FK_TAXI)
                                     WHERE (T.FK_AUTISTA = p_autista)
                                     AND (P.IDPRENOTAZIONE = p_id OR p_id IS NULL)
                                     AND (to_char(P.DATAORA, 'YYYY-MM-DD') BETWEEN
                                        (case when p_data_min IS NULL then '0001-01-01' else p_data_min END) AND
                                        (case when p_data_max IS NULL then '9999-12-31' else p_data_max END)
                                     )
                                     AND (to_char(P.DATAORA, 'HH24:MI') BETWEEN
                                        (case when p_ora_min IS NULL then '00:00' else p_ora_min END) AND
                                        (case when p_ora_max IS NULL then '23:59' else p_ora_max END)
                                     )
                                     AND (LOWER(replace(P.LUOGOPARTENZA, ' ', '')) = (LOWER(replace(p_partenza, ' ', ''))) OR p_partenza IS NULL)
                                     AND (P.Npersone = p_persone OR p_persone IS NULL)
                                     AND (LOWER(replace(P.LUOGOARRIVO, ' ', '')) = (LOWER(replace(p_arrivo, ' ', ''))) OR p_arrivo IS NULL)
                                     AND (P.STATO = p_stato OR p_stato IS NULL)
                                     AND (P.MODIFICATA = p_modificata OR p_modificata IS NULL)
                                     AND (P.DURATA = p_durata OR p_durata IS NULL)
                                     AND (P.DATAORA BETWEEN T.DATAORAINIZIOEFF AND T.DATAORAFINEEFF)
                                     AND (((p_categoria='standard' AND PS.FK_Prenotazione is not null) OR
                                        (p_categoria='accessibili' AND PA.FK_Prenotazione is not null) OR
                                        (p_categoria='lusso' AND PL.FK_Prenotazione is not null)
                                     ) OR p_categoria is null)
                                     ORDER BY P.IDPRENOTAZIONE DESC)
                    loop
                        gui.AGGIUNGIRIGATABELLA();
                        gui.AGGIUNGIELEMENTOTABELLA(prenotazione.IDPRENOTAZIONE);
                        gui.AGGIUNGIELEMENTOTABELLA(prenotazione.LUOGOPARTENZA);
                        gui.AGGIUNGIELEMENTOTABELLA(to_char(prenotazione.DATAORA, 'DD Month YYYY'));
                        gui.AGGIUNGIELEMENTOTABELLA(to_char(prenotazione.DATAORA, 'HH24:MI'));
                        gui.AGGIUNGIELEMENTOTABELLA(prenotazione.LUOGOARRIVO);

                        begin
                            select NPERSONEDISABILI
                            into passeggeriAccessibili
                            from PRENOTAZIONEACCESSIBILE
                            where FK_PRENOTAZIONE = prenotazione.IDPRENOTAZIONE;
                        exception
                            when others then
                                passeggeriAccessibili := 0;
                        end;

                        begin
                            select FK_PRENOTAZIONE
                            into lusso
                            from PRENOTAZIONELUSSO
                            where FK_PRENOTAZIONE = prenotazione.IDPRENOTAZIONE;
                        exception
                            when others then null;
                        end;

                        gui.APRIMODALPOPUP('Dettagli Prenotazione ' || prenotazione.IDPRENOTAZIONE, 'modal_' || prenotazione.IDPRENOTAZIONE);
                            gui.AGGIUNGIPARAGRAFO('Passeggeri: ' || prenotazione.NPERSONE);

                            if passeggeriAccessibili <> 0 then
                                gui.AGGIUNGIPARAGRAFO('Passeggeri accessibili: ' || passeggeriAccessibili);
                            end if;

                            if not lusso is null then
                                begin
                                    select count(*)
                                    into optionals
                                    from RICHIESTEPRENLUSSO
                                    where FK_PRENOTAZIONE = prenotazione.IDPRENOTAZIONE;

                                    if optionals > 0 then
                                        gui.AGGIUNGIPARAGRAFO('Optionals:');

                                        htp.prn('<ul>');
                                        for optional in (
                                            select *
                                            from OPTIONALS O
                                            join RICHIESTEPRENLUSSO RPL on O.IDOPTIONALS = RPL.FK_OPTIONALS
                                            where RPL.FK_PRENOTAZIONE = prenotazione.IDPRENOTAZIONE
                                            )
                                        loop
                                            htp.prn('<li>' || optional.NOME || '</li>');
                                        end loop;

                                        htp.prn('</ul>');
                                    else
                                        gui.AGGIUNGIPARAGRAFO('Optionals: nessuno');
                                    end if;
                                exception
                                    when others then
                                        gui.AGGIUNGIPARAGRAFO('Optionals: nessuno');
                                end;
                            end if;

                            case prenotazione.MODIFICATA
                                when 0 then gui.AGGIUNGIPARAGRAFO('Modificata: No');
                                when 1 then gui.AGGIUNGIPARAGRAFO('Modificata: Sì');
                            end case;

                            gui.AGGIUNGIPARAGRAFO('Stato: ' || prenotazione.STATO);
                            gui.AGGIUNGIPARAGRAFO('Durata: ' || prenotazione.DURATA || ' minuti');
                        gui.CHIUDIMODALPOPUP();

                        gui.apriElementoPulsanti;
                            gui.aggiungiPulsanteGenerale('''''', 'Info', 'modal_'||prenotazione.IDPRENOTAZIONE);
                        gui.chiudiElementoPulsanti;

                        gui.CHIUDIRIGATABELLA();
                    end loop;

                gui.CHIUDITABELLA();
            elsif (p_operatore is not null) then
                -- prenotazioni operatori
                begin
                    select D.NOME, D.COGNOME
                    into nome, cognome
                    from OPERATORI O
                    left join DIPENDENTI D on D.MATRICOLA = O.FK_DIPENDENTE
                    where (O.FK_DIPENDENTE = p_operatore);
                exception
                    when others then
                        gui.APRIPAGINA('Errore', p_idSess);
                        gui.AGGIUNGIPOPUP(false, 'Operatore inesistente!');
                        gui.CHIUDIPAGINA();
                        return;
                end;

                gui.APRIPAGINA('Prenotazioni | ' || nome || ' ' || cognome, p_idSess);
                gui.AGGIUNGIINTESTAZIONE('Prenotazioni di ' || nome || ' ' || cognome);
                gui.ACAPO();

                -- filtro
                gui.ApriFormFiltro(u_root || '.mvp');
                gui.AggiungiCampoFormFiltro('number', 'p_id', p_id, 'Codice', minimo=>0);
                gui.AggiungiCampoFormFiltro('text', 'p_partenza', p_partenza, 'Luogo di Partenza');
                gui.AggiungiCampoFormFiltro('text', 'p_arrivo', p_arrivo, 'Luogo di Arrivo');
                gui.AggiungiCampoFormFiltro('number', 'p_durata', p_durata, 'Durata');

                gui.AGGIUNGIRIGATABELLA();

                gui.AggiungiCampoFormFiltro('date', 'p_data_min', p_data_min, 'a partire da');
                gui.AggiungiCampoFormFiltro('date', 'p_data_max', p_data_max, 'fino a');
                gui.AggiungiCampoFormFiltro('time', 'p_ora_min', p_ora_min, 'a partire da');
                gui.AggiungiCampoFormFiltro('time', 'p_ora_max', p_ora_max, 'fino a');

                gui.AGGIUNGIRIGATABELLA();
                gui.AggiungiCampoFormFiltro('number', 'p_durata', p_durata, 'Durata');
                gui.AggiungiCampoFormFiltro('number', 'p_persone', p_persone, 'Persone');
                gui.APRISELECTFORMFILTRO('p_modificata', 'modificata');
                gui.AGGIUNGIOPZIONESELECT(p_modificata, true, 'modificata: ' || case
                                                                                    when p_modificata = 0 then 'no'
                                                                                    when p_modificata = 1 then 'si'
                                                                                    ELSE '' END);
                gui.AGGIUNGIOPZIONESELECT(0, false, 'non modificata');
                gui.AGGIUNGIOPZIONESELECT(1, false, 'modificata');
                gui.AGGIUNGIOPZIONESELECT(NULL, false, 'ANNULLA SELEZIONE');
                gui.CHIUDISELECTFORMFILTRO;

                gui.APRISELECTFORMFILTRO('p_stato', 'stato');
                gui.AGGIUNGIOPZIONESELECT(p_stato, true, 'stato: ' || p_stato);
                gui.AGGIUNGIOPZIONESELECT('accettata', false, 'accettata');
                gui.AGGIUNGIOPZIONESELECT('pendente', false, 'pendente');
                gui.AGGIUNGIOPZIONESELECT('rifiutata', false, 'rifiutata');
                gui.AGGIUNGIOPZIONESELECT('annullata', false, 'annullata');
                gui.AGGIUNGIOPZIONESELECT(NULL, false, 'ANNULLA SELEZIONE');
                gui.CHIUDISELECTFORMFILTRO;

                gui.AGGIUNGIRIGATABELLA();

                gui.APRISELECTFORMFILTRO('p_tipo', 'tipo');
                gui.AGGIUNGIOPZIONESELECT(p_tipo, true, 'tipo: ' || case
                                                                        when p_tipo = 0 then 'anonima'
                                                                        when p_tipo = 1 then 'non anonima'
                                                                        ELSE '' END);
                gui.AGGIUNGIOPZIONESELECT(0, false, 'anonima');
                gui.AGGIUNGIOPZIONESELECT(1, false, 'non anonima');
                gui.AGGIUNGIOPZIONESELECT(NULL, false, 'ANNULLA SELEZIONE');
                gui.CHIUDISELECTFORMFILTRO;

                gui.APRISELECTFORMFILTRO('p_categoria', 'categoria');
                gui.AGGIUNGIOPZIONESELECT(p_categoria, true, 'categoria: ' || p_categoria);
                gui.AGGIUNGIOPZIONESELECT('standard', false, 'standard');
                gui.AGGIUNGIOPZIONESELECT('lusso', false, 'lusso');
                gui.AGGIUNGIOPZIONESELECT('accessibili', false, 'accessibili');
                gui.AGGIUNGIOPZIONESELECT(NULL, false, 'ANNULLA SELEZIONE');
                gui.CHIUDISELECTFORMFILTRO;

                gui.AGGIUNGICAMPOFORMHIDDEN('text', 'p_idSess', p_idSess);
                gui.AGGIUNGICAMPOFORMHIDDEN('number', 'p_operatore', p_operatore);

                gui.AggiungiCampoFormFiltro('submit', '', '', 'filtra');
                gui.chiudiFormFiltro();
                gui.ACAPO();

                -- prenotazioni
                gui.APRITABELLA(headPrenotazioni);

                for prenotazione in (SELECT *
                                     FROM PRENOTAZIONI P
                                              LEFT JOIN ANONIMETELEFONICHE AN ON P.IDPRENOTAZIONE = AN.FK_PRENOTAZIONE
                                              LEFT JOIN NONANONIME NA ON P.IDPRENOTAZIONE = NA.FK_PRENOTAZIONE
                                              LEFT JOIN PRENOTAZIONESTANDARD PS ON P.IDPRENOTAZIONE = PS.FK_PRENOTAZIONE
                                              LEFT JOIN PRENOTAZIONEACCESSIBILE PA ON P.IDPRENOTAZIONE = PA.FK_PRENOTAZIONE
                                              LEFT JOIN PRENOTAZIONELUSSO PL ON P.IDPRENOTAZIONE = PL.FK_PRENOTAZIONE
                                     WHERE (NA.FK_OPERATORE = p_operatore OR AN.FK_OPERATORE = p_operatore)
                                     AND (P.IDPRENOTAZIONE = p_id OR p_id IS NULL)
                                     AND (to_char(P.DATAORA, 'YYYY-MM-DD') BETWEEN
                                        (case when p_data_min IS NULL then '0001-01-01' else p_data_min END) AND
                                        (case when p_data_max IS NULL then '9999-12-31' else p_data_max END)
                                     )
                                     AND (to_char(P.DATAORA, 'HH24:MI') BETWEEN
                                        (case when p_ora_min IS NULL then '00:00' else p_ora_min END) AND
                                        (case when p_ora_max IS NULL then '23:59' else p_ora_max END)
                                     )
                                     AND (LOWER(replace(P.LUOGOPARTENZA, ' ', '')) = (LOWER(replace(p_partenza, ' ', ''))) OR p_partenza IS NULL)
                                     AND (P.Npersone = p_persone OR p_persone IS NULL)
                                     AND (LOWER(replace(P.LUOGOARRIVO, ' ', '')) = (LOWER(replace(p_arrivo, ' ', ''))) OR p_arrivo IS NULL)
                                     AND (P.STATO = p_stato OR p_stato IS NULL)
                                     AND (P.MODIFICATA = p_modificata OR p_modificata IS NULL)
                                     AND (P.DURATA = p_durata OR p_durata IS NULL)
                                     AND ((p_categoria='standard' AND PS.FK_Prenotazione is not null) OR
                                        (p_categoria='accessibili' AND PA.FK_Prenotazione is not null) OR
                                        (p_categoria='lusso' AND PL.FK_Prenotazione is not null)
                                      OR (p_categoria is null))
                                     AND ((p_tipo=0 AND AN.FK_PRENOTAZIONE is not null) OR
                                          (p_tipo=1 AND NA.FK_PRENOTAZIONE is not null) OR
                                          p_tipo is null)
                                     ORDER BY P.IDPRENOTAZIONE DESC)
                    loop
                        gui.AGGIUNGIRIGATABELLA();
                        gui.AGGIUNGIELEMENTOTABELLA(prenotazione.IDPRENOTAZIONE);
                        gui.AGGIUNGIELEMENTOTABELLA(prenotazione.LUOGOPARTENZA);
                        gui.AGGIUNGIELEMENTOTABELLA(to_char(prenotazione.DATAORA, 'DD Month YYYY'));
                        gui.AGGIUNGIELEMENTOTABELLA(to_char(prenotazione.DATAORA, 'HH24:MI'));
                        gui.AGGIUNGIELEMENTOTABELLA(prenotazione.LUOGOARRIVO);

                        begin
                            select NPERSONEDISABILI
                            into passeggeriAccessibili
                            from PRENOTAZIONEACCESSIBILE
                            where FK_PRENOTAZIONE = prenotazione.IDPRENOTAZIONE;
                        exception
                            when others then
                                passeggeriAccessibili := 0;
                        end;

                        begin
                            select FK_PRENOTAZIONE
                            into lusso
                            from PRENOTAZIONELUSSO
                            where FK_PRENOTAZIONE = prenotazione.IDPRENOTAZIONE;
                        exception
                            when others then null;
                        end;

                        gui.APRIMODALPOPUP('Dettagli Prenotazione ' || prenotazione.IDPRENOTAZIONE, 'modal_' || prenotazione.IDPRENOTAZIONE);
                            gui.AGGIUNGIPARAGRAFO('Passeggeri: ' || prenotazione.NPERSONE);

                            if passeggeriAccessibili <> 0 then
                                gui.AGGIUNGIPARAGRAFO('Passeggeri accessibili: ' || passeggeriAccessibili);
                            end if;

                            if not lusso is null then
                                begin
                                    select count(*)
                                    into optionals
                                    from RICHIESTEPRENLUSSO
                                    where FK_PRENOTAZIONE = prenotazione.IDPRENOTAZIONE;

                                    if optionals > 0 then
                                        gui.AGGIUNGIPARAGRAFO('Optionals:');

                                        htp.prn('<ul>');
                                        for optional in (
                                            select *
                                            from OPTIONALS O
                                            join RICHIESTEPRENLUSSO RPL on O.IDOPTIONALS = RPL.FK_OPTIONALS
                                            where RPL.FK_PRENOTAZIONE = prenotazione.IDPRENOTAZIONE
                                            )
                                        loop
                                            htp.prn('<li>' || optional.NOME || '</li>');
                                        end loop;

                                        htp.prn('</ul>');
                                    else
                                        gui.AGGIUNGIPARAGRAFO('Optionals: nessuno');
                                    end if;
                                exception
                                    when others then
                                        gui.AGGIUNGIPARAGRAFO('Optionals: nessuno');
                                end;
                            end if;

                            case prenotazione.MODIFICATA
                                when 0 then gui.AGGIUNGIPARAGRAFO('Modificata: No');
                                when 1 then gui.AGGIUNGIPARAGRAFO('Modificata: Sì');
                            end case;

                            gui.AGGIUNGIPARAGRAFO('Stato: ' || prenotazione.STATO);
                            gui.AGGIUNGIPARAGRAFO('Durata: ' || prenotazione.DURATA || ' minuti');
                        gui.CHIUDIMODALPOPUP();

                        gui.apriElementoPulsanti;
                            gui.aggiungiPulsanteGenerale('''''', 'Info', 'modal_'||prenotazione.IDPRENOTAZIONE);
                        gui.chiudiElementoPulsanti;

                        gui.CHIUDIRIGATABELLA();
                    end loop;

                gui.CHIUDITABELLA();
            elsif (p_cliente is not null) then
                -- prenotazioni clienti
                begin
                    select C.NOME, C.COGNOME
                    into nome, cognome
                    from CLIENTI C
                    where (C.IDCLIENTE = p_cliente);
                exception
                    when others then
                        gui.APRIPAGINA('Errore', p_idSess);
                        gui.AGGIUNGIPOPUP(false, 'Cliente inesistente!');
                        gui.CHIUDIPAGINA();
                        return;
                end;

                gui.APRIPAGINA('Prenotazioni | ' || nome || ' ' || cognome, p_idSess);
                gui.AGGIUNGIINTESTAZIONE('Prenotazioni di ' || nome || ' ' || cognome);
                gui.ACAPO();

                -- filtro
                gui.ApriFormFiltro(u_root || '.mvp');
                gui.AggiungiCampoFormFiltro('number', 'p_id', p_id, 'Codice', minimo=>0);
                gui.AggiungiCampoFormFiltro('text', 'p_partenza', p_partenza, 'Luogo di Partenza');
                gui.AggiungiCampoFormFiltro('text', 'p_arrivo', p_arrivo, 'Luogo di Arrivo');
                gui.AggiungiCampoFormFiltro('number', 'p_durata', p_durata, 'Durata');

                gui.AGGIUNGIRIGATABELLA();

                gui.AggiungiCampoFormFiltro('date', 'p_data_min', p_data_min, 'a partire da');
                gui.AggiungiCampoFormFiltro('date', 'p_data_max', p_data_max, 'fino a');
                gui.AggiungiCampoFormFiltro('time', 'p_ora_min', p_ora_min, 'a partire da');
                gui.AggiungiCampoFormFiltro('time', 'p_ora_max', p_ora_max, 'fino a');

                gui.AGGIUNGIRIGATABELLA();
                gui.AggiungiCampoFormFiltro('number', 'p_durata', p_durata, 'Durata');
                gui.AggiungiCampoFormFiltro('number', 'p_persone', p_persone, 'Persone');
                gui.APRISELECTFORMFILTRO('p_modificata', 'modificata');
                gui.AGGIUNGIOPZIONESELECT(p_modificata, true, 'modificata: ' || case
                                                                                    when p_modificata = 0 then 'no'
                                                                                    when p_modificata = 1 then 'si'
                                                                                    ELSE '' END);
                gui.AGGIUNGIOPZIONESELECT(0, false, 'non modificata');
                gui.AGGIUNGIOPZIONESELECT(1, false, 'modificata');
                gui.AGGIUNGIOPZIONESELECT(NULL, false, 'ANNULLA SELEZIONE');
                gui.CHIUDISELECTFORMFILTRO;

                gui.APRISELECTFORMFILTRO('p_stato', 'stato');
                gui.AGGIUNGIOPZIONESELECT(p_stato, true, 'stato: ' || p_stato);
                gui.AGGIUNGIOPZIONESELECT('accettata', false, 'accettata');
                gui.AGGIUNGIOPZIONESELECT('pendente', false, 'pendente');
                gui.AGGIUNGIOPZIONESELECT('rifiutata', false, 'rifiutata');
                gui.AGGIUNGIOPZIONESELECT('annullata', false, 'annullata');
                gui.AGGIUNGIOPZIONESELECT(NULL, false, 'ANNULLA SELEZIONE');
                gui.CHIUDISELECTFORMFILTRO;

                gui.AGGIUNGIRIGATABELLA();

                gui.APRISELECTFORMFILTRO('p_tipo', 'tipo');
                gui.AGGIUNGIOPZIONESELECT(p_tipo, true, 'tipo: ' || case
                                                                        when p_tipo = 0 then 'online'
                                                                        when p_tipo = 1 then 'telefoniche'
                                                                        ELSE '' END);
                gui.AGGIUNGIOPZIONESELECT(0, false, 'online');
                gui.AGGIUNGIOPZIONESELECT(1, false, 'telefoniche');
                gui.AGGIUNGIOPZIONESELECT(NULL, false, 'ANNULLA SELEZIONE');
                gui.CHIUDISELECTFORMFILTRO;


                gui.APRISELECTFORMFILTRO('p_categoria', 'categoria');
                gui.AGGIUNGIOPZIONESELECT(p_categoria, true, 'categoria: ' || p_categoria);
                gui.AGGIUNGIOPZIONESELECT('standard', false, 'standard');
                gui.AGGIUNGIOPZIONESELECT('lusso', false, 'lusso');
                gui.AGGIUNGIOPZIONESELECT('accessibili', false, 'accessibili');
                gui.AGGIUNGIOPZIONESELECT(NULL, false, 'ANNULLA SELEZIONE');
                gui.CHIUDISELECTFORMFILTRO;

                gui.AGGIUNGICAMPOFORMHIDDEN('text', 'p_idSess', p_idSess);
                gui.AGGIUNGICAMPOFORMHIDDEN('number', 'p_cliente', p_cliente);

                gui.AggiungiCampoFormFiltro('submit', '', '', 'filtra');
                gui.chiudiFormFiltro();
                gui.ACAPO();

                -- prenotazioni
                gui.APRITABELLA(headPrenotazioni);

                for prenotazione in (SELECT *
                                     FROM PRENOTAZIONI P
                                              JOIN NONANONIME NA ON P.IDPRENOTAZIONE = NA.FK_PRENOTAZIONE
                                     LEFT JOIN PRENOTAZIONESTANDARD PS ON P.IDPRENOTAZIONE = PS.FK_PRENOTAZIONE
                                              LEFT JOIN PRENOTAZIONEACCESSIBILE PA ON P.IDPRENOTAZIONE = PA.FK_PRENOTAZIONE
                                              LEFT JOIN PRENOTAZIONELUSSO PL ON P.IDPRENOTAZIONE = PL.FK_PRENOTAZIONE
                                     WHERE (NA.FK_CLIENTE = p_cliente)
                                     AND (P.IDPRENOTAZIONE = p_id OR p_id IS NULL)
                                     AND (to_char(P.DATAORA, 'YYYY-MM-DD') BETWEEN
                                        (case when p_data_min IS NULL then '0001-01-01' else p_data_min END) AND
                                        (case when p_data_max IS NULL then '9999-12-31' else p_data_max END)
                                     )
                                     AND (to_char(P.DATAORA, 'HH24:MI') BETWEEN
                                        (case when p_ora_min IS NULL then '00:00' else p_ora_min END) AND
                                        (case when p_ora_max IS NULL then '23:59' else p_ora_max END)
                                     )
                                     AND (LOWER(replace(P.LUOGOPARTENZA, ' ', '')) = (LOWER(replace(p_partenza, ' ', ''))) OR p_partenza IS NULL)
                                     AND (P.Npersone = p_persone OR p_persone IS NULL)
                                     AND (LOWER(replace(P.LUOGOARRIVO, ' ', '')) = (LOWER(replace(p_arrivo, ' ', ''))) OR p_arrivo IS NULL)
                                     AND (P.STATO = p_stato OR p_stato IS NULL)
                                     AND (P.MODIFICATA = p_modificata OR p_modificata IS NULL)
                                     AND (P.DURATA = p_durata OR p_durata IS NULL)
                                     AND ((p_categoria='standard' AND PS.FK_Prenotazione is not null) OR
                                        (p_categoria='accessibili' AND PA.FK_Prenotazione is not null) OR
                                        (p_categoria='lusso' AND PL.FK_Prenotazione is not null)
                                      OR (p_categoria is null))
                                     AND ((p_tipo = NA.TIPO) OR
                                          p_tipo is null)
                                     ORDER BY P.IDPRENOTAZIONE DESC)
                    loop
                        gui.AGGIUNGIRIGATABELLA();
                        gui.AGGIUNGIELEMENTOTABELLA(prenotazione.IDPRENOTAZIONE);
                        gui.AGGIUNGIELEMENTOTABELLA(prenotazione.LUOGOPARTENZA);
                        gui.AGGIUNGIELEMENTOTABELLA(to_char(prenotazione.DATAORA, 'DD Month YYYY'));
                        gui.AGGIUNGIELEMENTOTABELLA(to_char(prenotazione.DATAORA, 'HH24:MI'));
                        gui.AGGIUNGIELEMENTOTABELLA(prenotazione.LUOGOARRIVO);

                         begin
                            select NPERSONEDISABILI
                            into passeggeriAccessibili
                            from PRENOTAZIONEACCESSIBILE
                            where FK_PRENOTAZIONE = prenotazione.IDPRENOTAZIONE;
                        exception
                            when others then
                                passeggeriAccessibili := 0;
                        end;

                        begin
                            select FK_PRENOTAZIONE
                            into lusso
                            from PRENOTAZIONELUSSO
                            where FK_PRENOTAZIONE = prenotazione.IDPRENOTAZIONE;
                        exception
                            when others then null;
                        end;

                        gui.APRIMODALPOPUP('Dettagli Prenotazione ' || prenotazione.IDPRENOTAZIONE, 'modal_' || prenotazione.IDPRENOTAZIONE);
                            gui.AGGIUNGIPARAGRAFO('Passeggeri: ' || prenotazione.NPERSONE);

                            if passeggeriAccessibili <> 0 then
                                gui.AGGIUNGIPARAGRAFO('Passeggeri accessibili: ' || passeggeriAccessibili);
                            end if;

                            if not lusso is null then
                                begin
                                    select count(*)
                                    into optionals
                                    from RICHIESTEPRENLUSSO
                                    where FK_PRENOTAZIONE = prenotazione.IDPRENOTAZIONE;

                                    if optionals > 0 then
                                        gui.AGGIUNGIPARAGRAFO('Optionals:');

                                        htp.prn('<ul>');
                                        for optional in (
                                            select *
                                            from OPTIONALS O
                                            join RICHIESTEPRENLUSSO RPL on O.IDOPTIONALS = RPL.FK_OPTIONALS
                                            where RPL.FK_PRENOTAZIONE = prenotazione.IDPRENOTAZIONE
                                            )
                                        loop
                                            htp.prn('<li>' || optional.NOME || '</li>');
                                        end loop;

                                        htp.prn('</ul>');
                                    else
                                        gui.AGGIUNGIPARAGRAFO('Optionals: nessuno');
                                    end if;
                                exception
                                    when others then
                                        gui.AGGIUNGIPARAGRAFO('Optionals: nessuno');
                                end;
                            end if;

                            case prenotazione.MODIFICATA
                                when 0 then gui.AGGIUNGIPARAGRAFO('Modificata: No');
                                when 1 then gui.AGGIUNGIPARAGRAFO('Modificata: Sì');
                            end case;

                            gui.AGGIUNGIPARAGRAFO('Stato: ' || prenotazione.STATO);
                            gui.AGGIUNGIPARAGRAFO('Durata: ' || prenotazione.DURATA || ' minuti');
                        gui.CHIUDIMODALPOPUP();

                        gui.apriElementoPulsanti;
                            gui.aggiungiPulsanteGenerale('''''', 'Info', 'modal_'||prenotazione.IDPRENOTAZIONE);
                        gui.chiudiElementoPulsanti;

                        gui.CHIUDIRIGATABELLA();
                    end loop;

                gui.CHIUDITABELLA();
            end if;
        end if;

        gui.CHIUDIPAGINA();
    exception
        when NoPermessi then
            gui.APRIPAGINA('Non autorizzato', p_idSess);
            gui.AGGIUNGIPOPUP(false, 'Non hai i permessi!');
            gui.CHIUDIPAGINA();
        when OTHERS then
            gui.APRIPAGINA('Errore sconosciuto', p_idSess);
            gui.AGGIUNGIPOPUP(false, 'Errore sconosciuto');
            gui.CHIUDIPAGINA();
    end mvp;
    
    procedure avviaCorsa(
        p_idSess SESSIONIDIPENDENTI.IDSESSIONE%TYPE default null,
        p_prenotazione PRENOTAZIONI.IDPRENOTAZIONE%TYPE default null,
        p_passeggeri CORSEPRENOTATE.PASSEGGERI%TYPE default null
    ) is
        corsa_attiva CORSEPRENOTATE.FK_PRENOTAZIONE%type;
        idTaxi TAXI.IDTAXI%type;
        postiTaxi TAXI.NPOSTI%type;
        postiAccessibili TAXIACCESSIBILE.NPERSONEDISABILI%type default 0;
    begin
        if not SESSIONHANDLER.CHECKRUOLO(p_idSess, 'Autista') then
            RAISE NoPermessi;
        end if;

        -- controllo se l'autista sta lavorando
        begin
            select TA.NPOSTI, T.FK_TAXI, TAC.NPERSONEDISABILI
            into postiTaxi, idTaxi, postiAccessibili
            from Taxi TA
            join Turni T on TA.IDTAXI = T.FK_TAXI
            left join TAXIACCESSIBILE TAC on TA.IDTAXI = TAC.FK_TAXI
            where T.FK_AUTISTA = SessionHandler.GETIDUSER(p_idSess)
                and (sysdate between T.DATAORAINIZIOEFF and T.DATAORAFINE);
        exception
            -- nessun dato trovato (i.e. l'autista non sta lavorando)
            when OTHERS then
                raise NoPermessi;
                RETURN;
        end;

        -- controllo se esiste una corsa avviata dall'autista ma mai terminata nel *turno attuale*
        begin
            select CP.FK_PRENOTAZIONE into corsa_attiva
                     from CORSEPRENOTATE CP
                     join PRENOTAZIONI P on CP.FK_PRENOTAZIONE = P.IDPRENOTAZIONE
                     left join PRENOTAZIONESTANDARD PS on P.IDPRENOTAZIONE = PS.FK_PRENOTAZIONE
                     left join PRENOTAZIONELUSSO PL on P.IDPRENOTAZIONE = PL.FK_PRENOTAZIONE
                     left join PRENOTAZIONEACCESSIBILE PA on P.IDPRENOTAZIONE = PA.FK_PRENOTAZIONE
                     where ((PS.FK_TAXI = idTaxi) or
                           (PL.FK_TAXI = idTaxi) or
                           (PA.FK_TAXIACCESSIBILE = idTaxi)) and
                           (CP.DURATA is null);
                    if corsa_attiva is null then
                        select CNP.IDCORSA into corsa_attiva
                        from CORSENONPRENOTATE CNP
                        where CNP.FK_STANDARD = idTaxi
                        and CNP.DURATA is null;
                    end if;
        exception
            when OTHERS then
                corsa_attiva := null;
        end;

        if not corsa_attiva is null then
            case corsa_attiva
                -- la corsa non terminata coincide con quella che si vuole avviare
                when p_prenotazione then
                    gui.REINDIRIZZA(u_root || '.visPrenAssegnateTaxi?p_idSess=' || p_idSess);
                    return;
                -- esiste una corsa non terminata
                else raise EsisteCorsaNonTerminata;
            end case;
        end if;

        if p_passeggeri < 1 or p_passeggeri > (postiTaxi + postiAccessibili) then
            raise ErrorePasseggeri;
        end if;

        if not p_prenotazione is null then
            begin
                savepoint s1;
                insert into CORSEPRENOTATE(FK_PRENOTAZIONE, DATAORA, PASSEGGERI) values (p_prenotazione, sysdate, p_passeggeri);
                commit;
            exception
                when dup_val_on_index then
                    rollback to s1;
                    raise EsisteCorsaTerminata;
                when others then
                    rollback to s1;
                    raise; -- propago l'errore
            end;
        else
            raise NOPERMESSI;
        end if;

        -- vai alla gestione delle prenotazioni
        gui.REINDIRIZZA(u_root || '.gestireCorsaPrenotata?p_idSess=' || p_idSess || '&p_id_prenotazione=' || p_prenotazione);
    exception
        when NoPermessi then
            gui.APRIPAGINA('Non autorizzato', p_idSess);
            gui.AGGIUNGIPOPUP(false, 'Non hai i permessi');
            gui.CHIUDIPAGINA();
        when EsisteCorsaNonTerminata then
            gui.APRIPAGINA('Errore', p_idSess);
            gui.AGGIUNGIPOPUP(false, 'Termina la corsa prima di avviarne un' || chr(39) || 'altra!');
            gui.CHIUDIPAGINA();
        when EsisteCorsaTerminata then
            gui.APRIPAGINA('Errore', p_idSess);
            gui.AGGIUNGIPOPUP(false, 'Corsa già terminata!');
            gui.CHIUDIPAGINA();
        when ErrorePasseggeri then
            gui.APRIPAGINA('Errore', p_idSess);
            gui.AGGIUNGIPOPUP(false, 'Numero di passeggeri non valido');
            gui.CHIUDIPAGINA();
        when OTHERS then
            gui.APRIPAGINA('Errore', p_idSess);
            gui.AGGIUNGIPOPUP(false, 'Errore sconosciuto');
            gui.CHIUDIPAGINA();
    end avviaCorsa;

    procedure luoghipopolari (
		p_idsess sessionidipendenti.idsessione%type default null
	) is
		type nomiarray is
			varray(10) of prenotazioni.luogopartenza%type;
		type conteggioarray is
			varray(10) of number;
		partenze      nomiarray;
		arrivi        nomiarray;
		partenzecount conteggioarray;
		arrivicount   conteggioarray;
		counter       number := 0;
		labels        varchar2(1200) default '';
		vals          varchar2(1200) default '';
	begin
		if not sessionhandler.checkruolo(
		                                p_idsess,
		                                'Manager'
		       ) then
			raise nopermessi;
		end if;
		partenze      := nomiarray();
		arrivi        := nomiarray();
		partenzecount := conteggioarray();
		arrivicount   := conteggioarray();
		gui.apripagina(
		              'Luoghi Popolari',
		              p_idsess
		);

        -- partenze
		for prenotazione in (
			select luogopartenza,
			       count(*) as n
			  from prenotazioni
			 group by luogopartenza
			 order by n desc
			 fetch first 10 rows only
		) loop
			counter                := counter + 1;
			partenze.extend();
			partenze(counter)      := prenotazione.luogopartenza;
			partenzecount.extend();
			partenzecount(counter) := prenotazione.n;

            -- creo le label per il grafico
			labels                 := labels
			          || '"'
			          || prenotazione.luogopartenza
			          || '", ';

            -- creo i valori per il grafico
			vals                   := vals
			        || ''
			        || prenotazione.n
			        || ', ';
		end loop;

		gui.aggiungiintestazione('Partenze più frequenti');
		gui.aggiungichart(
		                 'partenze',
		                 '
            {
    type: "bar",
    data: {
      labels: ['
		                 || labels
		                 || '],
      datasets: [{
        label: "Prenotazioni totali",
        data: ['
		                 || vals
		                 || '],
        borderWidth: 1
      }]
    },
    options: {
                                      layout: {
        autoPadding: true
    },
      scales: {
        y: {
          beginAtZero: true
        },
        x: {
                ticks: {
                    autoSkip: false,
                    maxRotation: 30,
                    minRotation: 30
                }
            }
      }
    }
  }
        '
		);

		gui.acapo();

        -- arrivi
		counter       := 0;
		labels        := '';
		vals          := '';
		for prenotazione in (
			select luogoarrivo,
			       count(*) as n
			  from prenotazioni
			 group by luogoarrivo
			 order by n desc
			 fetch first 10 rows only
		) loop
			counter              := counter + 1;
			arrivi.extend();
			arrivi(counter)      := prenotazione.luogoarrivo;
			arrivicount.extend();
			arrivicount(counter) := prenotazione.n;

            -- creo le label per il grafico
			labels               := labels
			          || '"'
			          || prenotazione.luogoarrivo
			          || '", ';

            -- creo i valori per il grafico
			vals                 := vals
			        || ''
			        || prenotazione.n
			        || ', ';
		end loop;

		gui.aggiungiintestazione('Arrivi più frequenti');
		gui.aggiungichart(
		                 'arrivi',
		                 '
            {
    type: "bar",
    data: {
      labels: ['
		                 || labels
		                 || '],
      datasets: [{
        label: "Prenotazioni totali",
        data: ['
		                 || vals
		                 || '],
        borderWidth: 1
      }]
    },
    options: {
        layout: {
        autoPadding: true
    },
        scales: {
        y: {
          beginAtZero: true
        },
        x: {
                ticks: {
                    autoSkip: false,
                    maxRotation: 30,
                    minRotation: 30
                }
            }
      }
    }
  }
        '
		);

		gui.acapo();
		gui.chiudipagina('Chart.defaults.font.size = 16;');
	exception
		when nopermessi then
			gui.apripagina(
			              'Non autorizzato',
			              p_idsess
			);
			gui.aggiungipopup(
			                 false,
			                 'Non hai i permessi'
			);
			gui.chiudipagina();
		when others then
			gui.apripagina(
			              'Errore',
			              p_idsess
			);
			gui.aggiungipopup(
			                 false,
			                 'Errore sconosciuto'
			);
			gui.chiudipagina();
	end luoghipopolari;

end gruppo1;
