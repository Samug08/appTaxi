create or replace package BODY  gruppo2 AS

----------------------  TAXI   ----------------------
    PROCEDURE visualizzaTaxi(
        id_ses in SessioniDipendenti.IDSessione%type,
        t_fkreferente in Taxi.FK_Referente%type default null,
        t_targa in Taxi.Targa%type default null,
        t_cilindrata in Taxi.Cilindrata%type default null,
        t_nposti in Taxi.Nposti%type default null,
        t_npersonedisabili in TaxiAccessibile.NpersoneDisabili%type default null,
        t_km in Taxi.Km%type default null,
        t_stato in Taxi.Stato%type default null,
        t_tariffa in Taxi.Tariffa%type default null,
        t_tipo in varchar2 default 'non_spec',
        t_stato_order in varchar2 default 'non_spec',
        t_cilindrata_min in Taxi.Cilindrata%type default null,
        t_cilindrata_max in Taxi.Cilindrata%type default null,
        t_km_min in Taxi.Km%type default null,
        t_km_max in Taxi.Km%type default null,
        message in varchar default '',
        negMessage in varchar default null)
        is
        head gui.StringArray;
        NomeAutista DIPENDENTI.NOME%type;
        CognomeAutista DIPENDENTI.COGNOME%type;
        tipoStandard NUMBER;
        tipoAccessibili NUMBER;
        tipoLusso NUMBER;
        b BOOLEAN;
        s BOOLEAN;
        tps BOOLEAN;
        tpa BOOLEAN;
        tpl BOOLEAN;
    begin

        -- INIZIALIZZAZIONE PAGINA
        IF SessionHandler.getRuolo(id_ses) = 'Cliente' OR SessionHandler.getRuolo(id_ses) = 'Contabile' THEN
            gui.ApriPagina('visualizzaTaxi', id_ses);
            gui.AGGIUNGIPOPUP(false,'Non hai il permesso per accedere a questa pagina', costanti.url||'gui.homePage?idSessione='||id_ses);
            return;
        end if;


        g2S.initialization(id_ses,'visualizzaTaxi', 'ELENCO TAXI');

        -- EVENTUALE MESSAGGIO
        IF message IS NOT NULL THEN
            gui.AggiungiPopup(successo => true, testo => message);
            gui.ACAPO(2);
        END IF;
        IF negMessage IS NOT NULL THEN
            gui.AggiungiPopup(successo => false, testo => negMessage);
            gui.ACAPO(2);
        END IF;

        -- SELECT PER OPERAZIONE STATISTICA
        SELECT ROUND(PercentualeStandard, 2), ROUND(PercentualeAccessibili, 2), ROUND(PercentualeLusso, 2) INTO tipoStandard, tipoAccessibili, tipoLusso
        FROM PercentualeUtilizzoTaxi;

        -- FORM
        gui.ApriFormFiltro(u_root || '.visualizzaTaxi');

        -- REFERENTE
        IF sessionHandler.getRuolo(id_ses) = 'Manager' OR sessionHandler.getRuolo(id_ses) = 'Operatore' THEN
            gui.ApriSelectFormFiltro('t_fkreferente', 'Referente', false);
            gui.AggiungiOpzioneSelect(t_fkreferente, b, 'Tutti');
            for x in (
                SELECT Matricola, Nome, Cognome
                FROM Dipendenti d
                Order By Matricola
            )
            loop
                IF t_fkreferente = x.Matricola THEN b := true; ELSE b := false; END IF;
                gui.AggiungiOpzioneSelect(x.Matricola, b, x.Matricola||' - '||x.Nome||' '||x.Cognome);
            END LOOP;
            gui.ChiudiSelectFormFiltro;
        END IF;
        gui.AggiungiCampoFormFiltro('text', 't_targa', '', 'Targa');
        gui.AggiungiCampoFormFiltro('number', 't_cilindrata_min', '', 'Cilindrata min');
        gui.AggiungiCampoFormFiltro('number', 't_cilindrata_max', '', 'Cilindrata max');
        gui.AggiungiCampoFormFiltro('number', 't_nposti', '', 'Posti');
        gui.AggiungiCampoFormFiltro('number', 't_km_min', '', 'Chilometri min');
        gui.AggiungiCampoFormFiltro('number', 't_km_max', '', 'Chilometri max');
        gui.AggiungiCampoFormFiltro('number', 't_tariffa', '', 'Tariffa');
        gui.apriselectformfiltro('t_stato_order', 'Stato', false);
        IF t_stato_order = 'non_spec' THEN s := true; ELSE s := false; END IF;
        gui.aggiungiOpzioneSelect('non_spec', tps, '-');
        IF t_stato_order = 'disponibile' THEN s := true; ELSE s := false; END IF;
        gui.AggiungiOpzioneSelect('disponibile', s, 'Disponibile');
        IF t_stato_order = 'non disponibile' THEN s := true; ELSE s := false; END IF;
        gui.AggiungiOpzioneSelect('non disponibile', s, 'Non disponibile');
        IF t_stato_order = 'occupato' THEN s := true; ELSE s := false; END IF;
        gui.AggiungiOpzioneSelect('occupato', s, 'Occupato');
        IF t_stato_order = 'prenotato' THEN s := true; ELSE s := false; END IF;
        gui.AggiungiOpzioneSelect('prenotato', s, 'Prenotato');
        IF t_stato_order = 'fermo' THEN s := true; ELSE s := false; END IF;
        gui.AggiungiOpzioneSelect('fermo', s, 'Fermo');
        gui.ChiudiSelectFormFiltro;

        -- Ordinamento per tipologia
        gui.apriSelectFormFiltro('t_tipo', 'Tipologia', false);
        IF t_tipo = 'non_spec' THEN tps := true; tpa := true; tpl := true;
            ELSE tps := false; tpa := false; tpl := false;
        END IF;
        gui.aggiungiOpzioneSelect('non_spec', tps, '-');
        IF t_tipo = 'STANDARD' THEN tps := true; ELSE tps := false; END IF;
        gui.AggiungiOpzioneSelect('STANDARD', tps, 'Standard');
        IF t_tipo = 'ACCESSIBILE' THEN tpa := true; ELSE tpa := false; END IF;
        gui.AggiungiOpzioneSelect('ACCESSIBILE', tpa, 'Accessibile');
        IF t_tipo = 'LUSSO' THEN tpl := true; ELSE tpl := false; END IF;
        gui.AggiungiOpzioneSelect('LUSSO', tpl, 'Lusso');
        gui.chiudiSelectFormFiltro;

        -- BOTTONE AGGIUNGI TAXI
        IF sessionhandler.getruolo(id_ses)='Manager' THEN
            gui.acapo();
            gui.BOTTONEAGGIUNGI('Aggiungi Taxi', url => u_root || '.inserisciTipologiaTaxi?id_ses=' || id_ses);
            gui.ACAPO();
        END IF;
        gui.AggiungiCampoFormFiltro(tipo => 'submit', nome => '', value => 'Filtra', placeholder => 'Filtra');
        gui.AGGIUNGICAMPOFORMHIDDEN(tipo => 'hidden', nome => 'id_ses', value => id_ses);
        gui.chiudiFormFiltro();
        gui.acapo();

        -- RESET FILTRO
        g2S.resetFilter(url => '.visualizzaTaxi', id_ses => id_ses);

        ----------------------------------------------------------------------------------------------------
        -- TABELLE PER AUTISTA

        -- TAXI DI CUI E' REFERENTE
        IF SessionHandler.getRuolo(id_ses) = 'Autista' THEN

            gui.AggiungiIntestazione('TAXI IN POSSESSO', 'h2');
            gui.aggiungiintestazione('Standard', 'h3');

            gui.APRITABELLA(gui.StringArray('Tipologia', 'Targa', 'Cilindrata', 'Posti',
                                            'Chilometraggio', 'Stato', 'Tariffa', ' '), ident => 'taxi_standard');
            -- TAXI STANDARD
            for x in (SELECT t.*
                    FROM TAXI t
                    LEFT JOIN TAXISTANDARD ts ON t.IDtaxi = ts.FK_Taxi
                    where (SessionHandler.getIdUser(id_ses) = t.FK_Referente)
                    and (ts.FK_TAXI = t.IDTAXI)
                    and (UPPER(replace(t.Targa, '','')) LIKE '%' || (UPPER(replace(t_targa,'',''))) || '%' or t_targa is null)
                    and (t.CILINDRATA <= t_cilindrata_max or t_cilindrata_max is null)
                    and (t.CILINDRATA >= t_cilindrata_min or t_cilindrata_min is null)
                    and (t.NPOSTI = t_nposti or t_nposti is null)
                    and (t.KM <= t_km_max or t_km_max is null)
                    and (t.KM >= t_km_min or t_km_min is null)
                    and (LOWER(replace(t.STATO, '', '')) = LOWER(replace(t_stato,'','')) or t_stato is null)
                    and (t.TARIFFA = t_tariffa or t_tariffa is null))
            loop

                IF t_stato_order = 'non_spec' OR x.Stato = t_stato_order THEN
                    gui.aggiungielementotabella('Standard');
                    gui.AggiungiElementoTabella('' || x.Targa || '');
                    gui.AggiungiElementoTabella('' || x.Cilindrata || '');
                    gui.AggiungiElementoTabella('' || x.Nposti || '');
                    gui.AggiungiElementoTabella('' || x.KM || '');
                    gui.AggiungiElementoTabella('' || x.Stato || '');
                    gui.AggiungiElementoTabella('' || x.Tariffa || '€' || '');
                    gui.apriElementoPulsanti;
                    gui.AGGIUNGIPULSANTEMODIFICA(u_root || '.modificaTaxi?id_ses=' || id_ses || '' || chr(38) || 't_idtaxi=' || x.IDtaxi || '' || chr(38) || 't_tipo=STANDARD' || '' || chr(38) || 't_stato=' || x.Stato);
                    gui.chiudiElementoPulsanti;
                    gui.ChiudiRigaTabella();
                END IF;
            end loop;

            gui.ChiudiTabella(ident => 'taxi_standard');
            gui.aggiungiintestazione('Accessibili', 'h3');
            gui.APRITABELLA(gui.StringArray('Tipologia', 'Targa', 'Cilindrata', 'Posti', 'Posti disabili',
                                            'Chilometraggio', 'Stato', 'Tariffa', ' '), ident => 'taxi_accessibile');

            -- TAXI ACCESSIBILE
            for x in (SELECT t.*, ta.NpersoneDisabili
                    FROM TAXI t
                    LEFT JOIN TAXIACCESSIBILE ta ON t.IDtaxi = ta.FK_Taxi
                    where (SessionHandler.getIdUser(id_ses) = t.FK_Referente)
                    and (ta.FK_TAXI = t.IDTAXI)
                    and (UPPER(replace(t.Targa, '','')) LIKE '%' || (UPPER(replace(t_targa,'',''))) || '%' or t_targa is null)
                    and (t.CILINDRATA <= t_cilindrata_max or t_cilindrata_max is null)
                    and (t.CILINDRATA >= t_cilindrata_min or t_cilindrata_min is null)
                    and (t.NPOSTI = t_nposti or t_nposti is null)
                    and (t.KM <= t_km_max or t_km_max is null)
                    and (t.KM >= t_km_min or t_km_min is null)
                    and (LOWER(replace(t.STATO, '', '')) = LOWER(replace(t_stato,'','')) or t_stato is null)
                    and (t.TARIFFA = t_tariffa or t_tariffa is null))
            loop

                IF t_stato_order = 'non_spec' OR x.Stato = t_stato_order THEN
                    gui.aggiungielementotabella('Accessibile');
                    gui.AggiungiElementoTabella('' || x.Targa || '');
                    gui.AggiungiElementoTabella('' || x.Cilindrata || '');
                    gui.AggiungiElementoTabella('' || x.Nposti || '');
                    gui.aggiungielementotabella('' || x.Npersonedisabili || '');
                    gui.AggiungiElementoTabella('' || x.KM || '');
                    gui.AggiungiElementoTabella('' || x.Stato || '');
                    gui.AggiungiElementoTabella('' || x.Tariffa || '€' || '');
                    gui.apriElementoPulsanti;
                    gui.AGGIUNGIPULSANTEMODIFICA(u_root || '.modificaTaxi?id_ses=' || id_ses || '' || chr(38) || 't_idtaxi=' || x.IDtaxi || '' || chr(38) || 't_tipo=STANDARD' || '' || chr(38) || 't_stato=' || x.Stato);
                    gui.chiudiElementoPulsanti;
                    gui.ChiudiRigaTabella();
                END IF;
            end loop;

            gui.ChiudiTabella(ident => 'taxi_accessibile');
            gui.aggiungiintestazione('Lusso', 'h3');
            gui.APRITABELLA(gui.StringArray('Tipologia', 'Targa', 'Cilindrata', 'Posti',
                                            'Chilometraggio', 'Stato', 'Tariffa', 'Optionals', ' '), ident => 'taxi_lusso');
            -- TAXI LUSSO
            for x in (SELECT t.*
                    FROM TAXI t
                    LEFT JOIN TAXILUSSO tl ON t.IDtaxi = tl.FK_Taxi
                    where (SessionHandler.getIdUser(id_ses) = t.FK_Referente)
                    and (tl.FK_TAXI = t.IDTAXI)
                    and (UPPER(replace(t.Targa, '','')) LIKE '%' || (UPPER(replace(t_targa,'',''))) || '%' or t_targa is null)
                    and (t.CILINDRATA <= t_cilindrata_max or t_cilindrata_max is null)
                    and (t.CILINDRATA >= t_cilindrata_min or t_cilindrata_min is null)
                    and (t.NPOSTI = t_nposti or t_nposti is null)
                    and (t.KM <= t_km_max or t_km_max is null)
                    and (t.KM >= t_km_min or t_km_min is null)
                    and (LOWER(replace(t.STATO, '', '')) = LOWER(replace(t_stato,'','')) or t_stato is null)
                    and (t.TARIFFA = t_tariffa or t_tariffa is null))
            loop

                IF t_stato_order = 'non_spec' OR x.Stato = t_stato_order THEN
                    gui.aggiungielementotabella('Lusso');
                    gui.AggiungiElementoTabella('' || x.Targa || '');
                    gui.AggiungiElementoTabella('' || x.Cilindrata || '');
                    gui.AggiungiElementoTabella('' || x.Nposti || '');
                    gui.AggiungiElementoTabella('' || x.KM || '');
                    gui.AggiungiElementoTabella('' || x.Stato || '');
                    gui.AggiungiElementoTabella('' || x.Tariffa || '€' || '');
                    gui.AggiungiBottoneTabella('Visualizza', url => u_root || '.visualizzaOptionals?id_ses=' || id_ses || '' || chr(38) || 'o_IDtaxi=' || x.IDtaxi);
                    gui.apriElementoPulsanti;
                    gui.AGGIUNGIPULSANTEMODIFICA(u_root || '.modificaTaxi?id_ses=' || id_ses || '' || chr(38) || 't_idtaxi=' || x.IDtaxi || '' || chr(38) || 't_tipo=STANDARD' || '' || chr(38) || 't_stato=' || x.Stato);
                    gui.chiudiElementoPulsanti;
                    gui.ChiudiRigaTabella();
                END IF;
            end loop;

            gui.ChiudiTabella(ident => 'taxi_lusso');

            -- TAXI CHE USERA'

            gui.AggiungiIntestazione('TAXI USATI', 'h2');
            gui.aggiungiintestazione('Standard', 'h3');
            gui.APRITABELLA(gui.StringArray('Tipologia', 'Targa', 'Cilindrata', 'Posti',
                                            'Chilometraggio', 'Stato', 'Tariffa', ' '), ident => 'taxi_standard_usati');
            -- TAXI STANDARD
            for x in (SELECT DISTINCT t.*
                    FROM TAXI t
                    LEFT JOIN TAXISTANDARD ts ON t.IDTAXI = ts.FK_TAXI
                    LEFT JOIN PRENOTAZIONESTANDARD ps ON  t.IDtaxi = ps.FK_Taxi
                    LEFT JOIN PRENOTAZIONI p ON ps.FK_Prenotazione = p.IDprenotazione
                    LEFT JOIN CORSENONPRENOTATE cnp ON t.IDtaxi = cnp.FK_Standard
                    where (SessionHandler.getIdUser(id_ses) = t.FK_Referente)
                    and (ts.FK_TAXI = t.IDTAXI)
                    and (UPPER(replace(t.Targa, '','')) LIKE '%' || (UPPER(replace(t_targa,'',''))) || '%' or t_targa is null)
                    and (t.CILINDRATA <= t_cilindrata_max or t_cilindrata_max is null)
                    and (t.CILINDRATA >= t_cilindrata_min or t_cilindrata_min is null)
                    and (t.NPOSTI = t_nposti or t_nposti is null)
                    and (t.KM <= t_km_max or t_km_max is null)
                    and (t.KM >= t_km_min or t_km_min is null)
                    and (LOWER(replace(t.STATO, '', '')) = LOWER(replace(t_stato,'','')) or t_stato is null)
                    and (t.TARIFFA = t_tariffa or t_tariffa is null)
                    and (p.Stato = 'accettata'))
            loop

                IF t_stato_order = 'non_spec' OR x.Stato = t_stato_order THEN
                    gui.aggiungielementotabella('Standard');
                    gui.AggiungiElementoTabella('' || x.Targa || '');
                    gui.AggiungiElementoTabella('' || x.Cilindrata || '');
                    gui.AggiungiElementoTabella('' || x.Nposti || '');
                    gui.AggiungiElementoTabella('' || x.KM || '');
                    gui.AggiungiElementoTabella('' || x.Stato || '');
                    gui.AggiungiElementoTabella('' || x.Tariffa || '€' || '');
                    gui.apriElementoPulsanti;
                    gui.AGGIUNGIPULSANTEMODIFICA(u_root || '.modificaTaxi?id_ses=' || id_ses || '' || chr(38) || 't_idtaxi=' || x.IDtaxi || '' || chr(38) || 't_tipo=STANDARD' || '' || chr(38) || 't_stato=' || x.Stato);
                    gui.chiudiElementoPulsanti;
                    gui.ChiudiRigaTabella();
                END IF;
            end loop;

            gui.ChiudiTabella(ident => 'taxi_standard_usati');
            gui.aggiungiintestazione('Accessibili', 'h3');
            gui.APRITABELLA(gui.StringArray('Tipologia', 'Targa', 'Cilindrata', 'Posti', 'Posti disabili',
                                            'Chilometraggio', 'Stato', 'Tariffa', ' '), ident => 'taxi_accessibili_usati');
            -- TAXI ACCESSIBILE
            for x in (SELECT DISTINCT t.*, ta.Npersonedisabili
                    FROM TAXI t
                    LEFT JOIN TAXIACCESSIBILE ta ON t.IDTAXI = ta.FK_TAXI
                    LEFT JOIN PRENOTAZIONESTANDARD ps ON  t.IDtaxi = ps.FK_Taxi
                    LEFT JOIN PRENOTAZIONI p ON ps.FK_Prenotazione = p.IDprenotazione
                    LEFT JOIN CORSENONPRENOTATE cnp ON t.IDtaxi = cnp.FK_Standard
                    where (SessionHandler.getIdUser(id_ses) = t.FK_Referente)
                    and (ta.FK_TAXI = t.IDTAXI)
                    and (UPPER(replace(t.Targa, '','')) LIKE '%' || (UPPER(replace(t_targa,'',''))) || '%' or t_targa is null)
                    and (t.CILINDRATA <= t_cilindrata_max or t_cilindrata_max is null)
                    and (t.CILINDRATA >= t_cilindrata_min or t_cilindrata_min is null)
                    and (t.NPOSTI = t_nposti or t_nposti is null)
                    and (t.KM <= t_km_max or t_km_max is null)
                    and (t.KM >= t_km_min or t_km_min is null)
                    and (LOWER(replace(t.STATO, '', '')) = LOWER(replace(t_stato,'','')) or t_stato is null)
                    and (t.TARIFFA = t_tariffa or t_tariffa is null)
                    and (p.Stato = 'accettata'))
            loop

                IF t_stato_order = 'non_spec' OR x.Stato = t_stato_order THEN
                    gui.aggiungielementotabella('Accessibile');
                    gui.AggiungiElementoTabella('' || x.Targa || '');
                    gui.AggiungiElementoTabella('' || x.Cilindrata || '');
                    gui.AggiungiElementoTabella('' || x.Nposti || '');
                    gui.AggiungiElementoTabella('' || x.Npersonedisabili || '');
                    gui.AggiungiElementoTabella('' || x.KM || '');
                    gui.AggiungiElementoTabella('' || x.Stato || '');
                    gui.AggiungiElementoTabella('' || x.Tariffa || '€' || '');
                    gui.apriElementoPulsanti;
                    gui.AGGIUNGIPULSANTEMODIFICA(u_root || '.modificaTaxi?id_ses=' || id_ses || '' || chr(38) || 't_idtaxi=' || x.IDtaxi || '' || chr(38) || 't_tipo=STANDARD' || '' || chr(38) || 't_stato=' || x.Stato);
                    gui.chiudiElementoPulsanti;
                    gui.ChiudiRigaTabella();
                END IF;
            end loop;

            gui.ChiudiTabella(ident => 'taxi_accessibili_usati');
            gui.aggiungiintestazione('Lusso', 'h3');
            gui.APRITABELLA(gui.StringArray('Tipologia', 'Targa', 'Cilindrata', 'Posti',
                                            'Chilometraggio', 'Stato', 'Tariffa','Optionals', ' '), ident => 'taxi_lusso_usati');
            -- TAXI LUSSO
            for x in (SELECT DISTINCT t.*
                    FROM TAXI t
                    LEFT JOIN TAXILUSSO tl ON t.IDTAXI = tl.FK_TAXI
                    LEFT JOIN PRENOTAZIONESTANDARD ps ON  t.IDtaxi = ps.FK_Taxi
                    LEFT JOIN PRENOTAZIONI p ON ps.FK_Prenotazione = p.IDprenotazione
                    LEFT JOIN CORSENONPRENOTATE cnp ON t.IDtaxi = cnp.FK_Standard
                    where (SessionHandler.getIdUser(id_ses) = t.FK_Referente)
                    and (tl.FK_TAXI = t.IDTAXI)
                    and (UPPER(replace(t.Targa, '','')) LIKE '%' || (UPPER(replace(t_targa,'',''))) || '%' or t_targa is null)
                    and (t.CILINDRATA <= t_cilindrata_max or t_cilindrata_max is null)
                    and (t.CILINDRATA >= t_cilindrata_min or t_cilindrata_min is null)
                    and (t.NPOSTI = t_nposti or t_nposti is null)
                    and (t.KM <= t_km_max or t_km_max is null)
                    and (t.KM >= t_km_min or t_km_min is null)
                    and (LOWER(replace(t.STATO, '', '')) = LOWER(replace(t_stato,'','')) or t_stato is null)
                    and (t.TARIFFA = t_tariffa or t_tariffa is null)
                    and (p.Stato = 'accettata'))
            loop

                IF t_stato_order = 'non_spec' OR x.Stato = t_stato_order THEN
                    gui.aggiungielementotabella('Lusso');
                    gui.AggiungiElementoTabella('' || x.Targa || '');
                    gui.AggiungiElementoTabella('' || x.Cilindrata || '');
                    gui.AggiungiElementoTabella('' || x.Nposti || '');
                    gui.AggiungiElementoTabella('' || x.KM || '');
                    gui.AggiungiElementoTabella('' || x.Stato || '');
                    gui.AggiungiElementoTabella('' || x.Tariffa || '€' || '');
                    gui.AggiungiBottoneTabella('Visualizza', url => u_root || '.visualizzaOptionals?id_ses=' || id_ses || '' || chr(38) || 'o_IDtaxi=' || x.IDtaxi);
                    gui.apriElementoPulsanti;
                    gui.AGGIUNGIPULSANTEMODIFICA(u_root || '.modificaTaxi?id_ses=' || id_ses || '' || chr(38) || 't_idtaxi=' || x.IDtaxi || '' || chr(38) || 't_tipo=STANDARD' || '' || chr(38) || 't_stato=' || x.Stato);
                    gui.chiudiElementoPulsanti;
                    gui.ChiudiRigaTabella();
                END IF;
            end loop;

            gui.ChiudiTabella(ident => 'taxi_lusso_usati');
        END IF;

        ----------------------------------------------------------------------------------------------------

        -- TABELLE PER MANAGER E OPERATORE

        -- TABELLA TAXI STANDARD
        
        IF SessionHandler.getRuolo(id_ses) = 'Manager' OR SessionHandler.getRuolo(id_ses) = 'Operatore' THEN

            IF tps = true OR t_tipo = 'non_spec' THEN
                gui.AggiungiIntestazione('TAXI STANDARD', 'h2');
                IF sessionhandler.getruolo(id_ses)='Manager' THEN
                    gui.AggiungiIntestazione('I taxi standard sono stati utilizzati per il ' || tipoStandard || '%', 'h5');
                    gui.BOTTONEAGGIUNGI('Utilizzo Taxi Standard', url => u_root || '.UtilizzoTaxi?id_ses=' || id_ses || '' || chr(38) || 't_tipo=' || 'STANDARD');
                END IF;
                gui.acapo();

                gui.APRITABELLA(gui.StringArray('Referente', 'Targa', 'Cilindrata', 'Posti',
                                            'Chilometraggio', 'Stato', 'Tariffa', ' '), ident => 'taxi_standard');

                -- QUERY
                for x in (SELECT t.*
                            FROM TAXI t
                            LEFT JOIN TAXISTANDARD ts ON t.IDtaxi = ts.FK_Taxi
                            where (ts.FK_TAXI = t.IDTAXI)
                            and (t.FK_Referente =  t_fkreferente or t_fkreferente is null)
                            and (UPPER(replace(t.Targa, '','')) LIKE '%' || (UPPER(replace(t_targa,'',''))) || '%' or t_targa is null)
                            and (t.CILINDRATA <= t_cilindrata_max or t_cilindrata_max is null)
                            and (t.CILINDRATA >= t_cilindrata_min or t_cilindrata_min is null)
                            and (t.NPOSTI = t_nposti or t_nposti is null)
                            and (t.KM <= t_km_max or t_km_max is null)
                            and (t.KM >= t_km_min or t_km_min is null)
                            and (LOWER(replace(t.STATO, '', '')) = LOWER(replace(t_stato,'','')) or t_stato is null)
                            and (t.TARIFFA = t_tariffa or t_tariffa is null))
                    loop

                        IF t_stato_order = 'non_spec' OR x.Stato = t_stato_order THEN

                            -- QUERY AUTISTI
                            SELECT d.Nome, d.Cognome INTO NomeAutista, CognomeAutista
                            FROM DIPENDENTI d
                            WHERE d.Matricola = x.FK_Referente;

                            gui.AggiungiRigaTabella();
                            IF sessionhandler.getruolo(id_ses)='Manager' THEN
                                gui.apriElementoPulsanti;
                                gui.AggiungiPulsanteGenerale(testo => NomeAutista || ' ' || CognomeAutista,
                                                            collegamento => ''''||link || '' ||u_user||'.gruppo4.visualizzaDipendente?idSessione=' || id_ses
                                                                                || chr(38) || 'IMatricola='||x.fk_referente||'''');
                                gui.chiudiElementoPulsanti;
                            ELSE IF sessionhandler.getruolo(id_ses)='Operatore' THEN
                                gui.AggiungiElementoTabella('' || NomeAutista || ' ' || CognomeAutista ||'');
                            END IF;
                            END IF;
                            gui.apriElementoPulsanti;
                                gui.AggiungiPulsanteGenerale(testo => x.Targa  || '',collegamento => ''''||u_root || '.visualizzaUnTaxi?id_ses=' || id_ses || '' || chr(38) || 't_IDtaxi=' || x.IDtaxi||'''');
                            gui.chiudiElementoPulsanti;
                            gui.AggiungiElementoTabella('' || x.Cilindrata || '');
                            gui.AggiungiElementoTabella('' || x.Nposti || '');
                            gui.AggiungiElementoTabella('' || x.KM || '');
                            gui.AggiungiElementoTabella('' || x.Stato || '');
                            gui.AggiungiElementoTabella('' || x.Tariffa || '€' || '');
                            IF sessionhandler.getruolo(id_ses)='Autista' or sessionhandler.getruolo(id_ses)='Manager' THEN
                                gui.apriElementoPulsanti;
                                gui.AGGIUNGIPULSANTEMODIFICA(u_root || '.modificaTaxi?id_ses=' || id_ses || '' || chr(38) || 't_idtaxi=' || x.IDtaxi || '' || chr(38) || 't_tipo=STANDARD' || '' || chr(38) || 't_stato=' || x.Stato);
                                gui.chiudiElementoPulsanti;
                            END IF;
                            gui.ChiudiRigaTabella();
                        END IF;
                end loop;

                gui.ChiudiTabella(ident => 'taxi_standard');
            END IF;

            -- TABELLA TAXI ACCESSIBILI

            IF tpa = true OR t_tipo = 'non_spec' THEN
                gui.AggiungiIntestazione('TAXI ACCESSIBILI', 'h2');
                IF sessionhandler.getruolo(id_ses)='Manager' THEN
                    gui.AggiungiIntestazione('I taxi accessibili sono stati utilizzati per il ' || tipoAccessibili || '%', 'h5');
                    gui.BOTTONEAGGIUNGI('Utilizzo Taxi Accessibili', url => u_root || '.UtilizzoTaxi?id_ses=' || id_ses || '' || chr(38) || 't_tipo=' || 'ACCESSIBILI');
                END IF;
                gui.acapo();
                gui.APRITABELLA(gui.StringArray('Referente', 'Targa', 'Cilindrata', 'Posti', 'Posti disabili',
                                    'Chilometraggio', 'Stato', 'Tariffa', ' '), ident => 'taxi_accessibili');

                -- QUERY

                for i in (SELECT t.*, ta.NpersoneDisabili
                            FROM TAXI t
                            LEFT JOIN TAXIACCESSIBILE ta ON t.IDtaxi = ta.FK_Taxi
                            where (ta.FK_TAXI = t.IDTAXI)
                            and (t.FK_Referente =  t_fkreferente or t_fkreferente is null)
                            and (UPPER(replace(t.Targa, '','')) LIKE '%' || (UPPER(replace(t_targa,'',''))) || '%' or t_targa is null)
                            and (t.CILINDRATA <= t_cilindrata_max or t_cilindrata_max is null)
                            and (t.CILINDRATA >= t_cilindrata_min or t_cilindrata_min is null)
                            and (t.NPOSTI = t_nposti or t_nposti is null)
                            and (t.KM <= t_km_max or t_km_max is null)
                            and (t.KM >= t_km_min or t_km_min is null)
                            and (LOWER(replace(t.STATO, '', '')) = LOWER(replace(t_stato,'','')) or t_stato is null)
                            and (t.TARIFFA = t_tariffa or t_tariffa is null))
                    loop
                        IF t_stato_order = 'non_spec' OR i.Stato = t_stato_order THEN

                            -- QUERY AUTISTA
                            SELECT d.Nome, d.Cognome INTO NomeAutista, CognomeAutista
                            FROM DIPENDENTI d
                            WHERE d.Matricola = i.FK_Referente;

                            gui.AggiungiRigaTabella();
                            IF sessionhandler.getruolo(id_ses)='Manager' THEN
                                gui.apriElementoPulsanti;
                                gui.AggiungiPulsanteGenerale(testo => NomeAutista || ' ' || CognomeAutista,
                                                            collegamento => ''''||link || '' ||u_user||'.gruppo4.visualizzaDipendente?idSessione=' || id_ses
                                                                                || chr(38) || 'IMatricola='||i.fk_referente||'''');
                                gui.chiudiElementoPulsanti;
                            ELSE IF sessionhandler.getruolo(id_ses)='Operatore' THEN
                                gui.AggiungiElementoTabella('' || NomeAutista || ' ' || CognomeAutista ||'');
                            END IF;
                            END IF;
                             gui.apriElementoPulsanti;
                                gui.AggiungiPulsanteGenerale(testo => i.Targa  || '',collegamento => ''''||u_root || '.visualizzaUnTaxi?id_ses=' || id_ses || '' || chr(38) || 't_IDtaxi=' || i.IDtaxi||'''');
                            gui.chiudiElementoPulsanti;
                            gui.AggiungiElementoTabella('' || i.Cilindrata || '');
                            gui.AggiungiElementoTabella('' || i.Nposti || '');
                            gui.AggiungiElementoTabella('' || i.Npersonedisabili || '');
                            gui.AggiungiElementoTabella('' || i.KM || '');
                            gui.AggiungiElementoTabella('' || i.Stato || '');
                            gui.AggiungiElementoTabella('' || i.Tariffa || '€' || '');
                            IF sessionhandler.getruolo(id_ses)='Manager' THEN
                                gui.apriElementoPulsanti;
                                gui.AGGIUNGIPULSANTEMODIFICA(u_root || '.modificaTaxi?id_ses=' || id_ses || '' || chr(38) || 't_idtaxi=' || i.IDtaxi || '' || chr(38) || 't_tipo=ACCESSIBILE' || '' || chr(38) || 't_stato=' || i.Stato);
                                gui.chiudiElementoPulsanti;
                            END IF;
                            gui.ChiudiRigaTabella();
                        END IF;
                    end loop;

                gui.ChiudiTabella(ident => 'taxi_accessibili');

            END IF;

            -- TABELLA TAXI LUSSO
            IF tpl = true OR t_tipo = 'non_spec' THEN
                gui.AggiungiIntestazione('TAXI LUSSO', 'h2');
                IF sessionhandler.getruolo(id_ses)='Manager' THEN
                 gui.AggiungiIntestazione('I taxi di lusso sono stati utilizzati per il ' || tipoLusso || '%', 'h5');
                    gui.BOTTONEAGGIUNGI('Utilizzo Taxi Lusso', url => u_root || '.UtilizzoTaxi?id_ses=' || id_ses || '' || chr(38) || 't_tipo=' || 'LUSSO');
                END IF;
                gui.acapo();
                IF sessionhandler.getruolo(id_ses)='Operatore' THEN
                    gui.APRITABELLA(gui.StringArray('Referente', 'Targa', 'Cilindrata', 'Posti',
                                        'Chilometraggio', 'Stato', 'Tariffa', ' '), ident => 'taxi_lusso');
                END IF;

                IF sessionhandler.getruolo(id_ses)='Manager' THEN
                    gui.APRITABELLA(gui.StringArray('Referente', 'Targa', 'Cilindrata', 'Posti',
                                        'Chilometraggio', 'Stato', 'Tariffa', 'Optionals', ' '), ident => 'taxi_lusso');
                END IF;
                -- QUERY
                for i in (SELECT t.*
                            FROM TAXI t
                            LEFT JOIN TAXILUSSO tl ON t.IDtaxi = tl.FK_Taxi
                            where (tl.FK_TAXI = t.IDTAXI)
                            and (t.FK_Referente =  t_fkreferente or t_fkreferente is null)
                            and (UPPER(replace(t.Targa, '','')) LIKE '%' || (UPPER(replace(t_targa,'',''))) || '%' or t_targa is null)
                            and (t.CILINDRATA <= t_cilindrata_max or t_cilindrata_max is null)
                            and (t.CILINDRATA >= t_cilindrata_min or t_cilindrata_min is null)
                            and (t.NPOSTI = t_nposti or t_nposti is null)
                            and (t.KM <= t_km_max or t_km_max is null)
                            and (t.KM >= t_km_min or t_km_min is null)
                            and (LOWER(replace(t.STATO, '', '')) = LOWER(replace(t_stato,'','')) or t_stato is null)
                            and (t.TARIFFA = t_tariffa or t_tariffa is null))
                    loop
                        IF t_stato_order = 'non_spec' OR i.Stato = t_stato_order THEN

                            -- QUERY AUTISTI
                            SELECT d.Nome, d.Cognome INTO NomeAutista, CognomeAutista
                            FROM DIPENDENTI d
                            WHERE d.Matricola = i.FK_Referente;

                            gui.AggiungiRigaTabella();
                            IF sessionhandler.getruolo(id_ses)='Manager' THEN
                                gui.apriElementoPulsanti;
                                gui.AggiungiPulsanteGenerale(testo => NomeAutista || ' ' || CognomeAutista,
                                                            collegamento => ''''||link || '' ||u_user||'.gruppo4.visualizzaDipendente?idSessione=' || id_ses
                                                                                || chr(38) || 'IMatricola='||i.fk_referente||'''');
                                gui.chiudiElementoPulsanti;
                            ELSE IF sessionhandler.getruolo(id_ses)='Operatore' THEN
                                gui.AggiungiElementoTabella('' || NomeAutista || ' ' || CognomeAutista ||'');
                            END IF;
                            END IF;
                             gui.apriElementoPulsanti;
                                gui.AggiungiPulsanteGenerale(testo => i.Targa  || '',collegamento => ''''||u_root || '.visualizzaUnTaxi?id_ses=' || id_ses || '' || chr(38) || 't_IDtaxi=' || i.IDtaxi||'''');
                            gui.chiudiElementoPulsanti;
                            gui.AggiungiElementoTabella('' || i.Cilindrata || '');
                            gui.AggiungiElementoTabella('' || i.Nposti || '');
                            gui.AggiungiElementoTabella('' || i.KM || '');
                            gui.AggiungiElementoTabella('' || i.Stato || '');
                            gui.AggiungiElementoTabella('' || i.Tariffa || '€' || '');
                            IF sessionhandler.getruolo(id_ses)='Manager' THEN
                                gui.AggiungiBottoneTabella('Visualizza', url => u_root || '.visualizzaOptionals?id_ses=' || id_ses || '' || chr(38) || 'o_IDtaxi=' || i.IDtaxi);
                            END IF;
                            IF sessionhandler.getruolo(id_ses)='Manager' THEN
                                gui.apriElementoPulsanti;
                                gui.AGGIUNGIPULSANTEMODIFICA(u_root || '.modificaTaxi?id_ses=' || id_ses || '' || chr(38) || 't_idtaxi=' || i.IDtaxi || '' || chr(38) || 't_tipo=LUSSO' || '' || chr(38) || 't_stato=' || i.Stato);
                                gui.chiudiElementoPulsanti;
                            END IF;
                            gui.ChiudiRigaTabella();
                        END IF;
                    end loop;

                gui.ChiudiTabella(ident => 'taxi_lusso');
            END IF;
        
        END IF;

        gui.ACAPO(2);
        gui.CHIUDIPAGINA();

    end visualizzaTaxi;

    PROCEDURE visualizzaUnTaxi(
        id_ses in SESSIONIDIPENDENTI.IDsessione%type,
        t_IDtaxi in TAXI.IDTAXI%type default null,
        t_fkreferente in TAXI.FK_REFERENTE%type default null,
        t_targa in TAXI.TARGA%type default null,
        t_cilindrata in TAXI.CILINDRATA%type default null,
        t_nposti in TAXI.NPOSTI%type default null,
        t_npersonedisabili in TAXIACCESSIBILE.NPERSONEDISABILI%type default null,
        t_km in TAXI.KM%type default null,
        t_stato in TAXI.STATO%type default null,
        t_tariffa in TAXI.TARIFFA%type default null,
        message in varchar2 default ''
    ) is
    NomeAutista DIPENDENTI.NOME%type;
    CognomeAutista DIPENDENTI.COGNOME%type;
    targaTaxi TAXI.TARGA%type;
    tipoTaxi VARCHAR(15);
    begin

        -- INIZIALIZZAZIONE PAGINA PER CLIENTE E CONTABILE
        IF SessionHandler.getRuolo(id_ses) = 'Cliente' OR SessionHandler.getRuolo(id_ses) = 'Contabile' THEN
            gui.ApriPagina('visualizzaTaxi', id_ses);
            gui.AGGIUNGIPOPUP(false,'Non hai il permesso per accedere a questa pagina', costanti.url||'gui.homePage?idSessione='||id_ses);
            return;
        end if;

        -- TARGA
        select targa into targaTaxi from TAXI t where t.IDTAXI = t_idtaxi;

        -- INIZIALIZZAZIONE PAGINA
        g2S.initialization(id_ses,'visualizzaUnTaxi', 'VISUALIZZAZIONE TAXI:  ' ||  targaTaxi);

        -- EVENTUALE MESSAGGIO
        IF message IS NOT NULL THEN
            gui.AggiungiPopup(successo => true, testo => message);
            gui.ACAPO(2);
        end if;
        SELECT
        CASE
            WHEN ts.FK_Taxi IS NOT NULL THEN 'Standard'
            WHEN ta.FK_Taxi IS NOT NULL THEN 'Accessibile'
            WHEN tl.FK_Taxi IS NOT NULL THEN 'Lusso'
            ELSE 'Non trovato'
        END INTO tipoTaxi
        FROM TAXI t
        LEFT JOIN TAXISTANDARD ts ON t.IDtaxi = ts.FK_Taxi
        LEFT JOIN TAXIACCESSIBILE ta ON t.IDtaxi = ta.FK_Taxi
        LEFT JOIN TAXILUSSO tl ON t.IDtaxi = tl.FK_Taxi
        WHERE t.IDtaxi = t_IDtaxi;

        gui.AGGIUNGIINTESTAZIONE('TIPOLOGIA: ' || tipoTaxi);
        gui.acapo(2);

       --TAXI STANDARD
        if tipoTaxi = 'Standard' then
            gui.APRITABELLA(gui.StringArray('Referente', 'Targa', 'Cilindrata', 'Posti',
                                'Chilometraggio', 'Stato', 'Tariffa', ' '));

            -- QUERY
            for x in (SELECT t.*
                    FROM TAXI t
                    LEFT JOIN TAXISTANDARD  ts ON t.IDtaxi = ts.FK_Taxi
                    where (ts.FK_TAXI = t.IDTAXI)
                    and (t.FK_Referente =  t_fkreferente or t_fkreferente is null)
                    and (UPPER(replace(t.Targa, '','')) LIKE '%' || (UPPER(replace(t_targa,'',''))) || '%' or t_targa is null)
                    and (t.CILINDRATA = t_cilindrata or t_cilindrata is null)
                    and (t.NPOSTI = t_nposti or t_nposti is null)
                    and (t.KM = t_km or t_km is null)
                    and (LOWER(replace(t.STATO, '', '')) = LOWER(replace(t_stato,'','')) or t_stato is null)
                    and (t.TARIFFA = t_tariffa or t_tariffa is null))
            loop
            if t_IDtaxi = x.IDTAXI then
                gui.AggiungiRigaTabella();

                SELECT d.Nome, d.Cognome INTO NomeAutista, CognomeAutista
                FROM DIPENDENTI d
                WHERE d.Matricola = x.FK_Referente;

                gui.AggiungiElementoTabella('' || NomeAutista || ' ' || CognomeAutista ||'');
                gui.AggiungiElementoTabella('' || x.Targa || '');
                gui.AggiungiElementoTabella('' || x.Cilindrata || '');
                gui.AggiungiElementoTabella('' || x.Nposti || '');
                gui.AggiungiElementoTabella('' || x.KM || '');
                gui.AggiungiElementoTabella('' || x.Stato || '');
                gui.AggiungiElementoTabella('' || x.Tariffa || '€' || '');
                gui.CHIUDIRIGATABELLA();
            end if;
            end loop;

        gui.CHIUDITABELLA();
        end if;

        --TAXI ACCESSIBILE
        if tipoTaxi = 'Accessibile' then
            gui.APRITABELLA(gui.StringArray('Referente', 'Targa', 'Cilindrata', 'Posti', 'Posti disabili',
                                'Chilometraggio', 'Stato', 'Tariffa', ' '));
            for i in (SELECT t.*, ta.NpersoneDisabili
                    FROM TAXI t
                    LEFT JOIN TAXIACCESSIBILE ta ON t.IDtaxi = ta.FK_Taxi
                    where (ta.FK_TAXI = t.IDTAXI)
                    and (t.FK_Referente =  t_fkreferente or t_fkreferente is null)
                    and (UPPER(replace(t.Targa, '','')) LIKE '%' || (UPPER(replace(t_targa,'',''))) || '%' or t_targa is null)
                    and (t.CILINDRATA = t_cilindrata or t_cilindrata is null)
                    and (t.NPOSTI = t_nposti or t_nposti is null)
                    and (t.KM = t_km or t_km is null)
                    and (LOWER(replace(t.STATO, '', '')) = LOWER(replace(t_stato,'','')) or t_stato is null)
                    and (t.TARIFFA = t_tariffa or t_tariffa is null))
            loop
            if t_IDtaxi = i.IDTAXI then
                gui.AggiungiRigaTabella();

                SELECT d.Nome, d.Cognome INTO NomeAutista, CognomeAutista
                FROM DIPENDENTI d
                WHERE d.Matricola = i.FK_Referente;

                gui.AggiungiElementoTabella('' || NomeAutista || ' ' || CognomeAutista ||'');
                gui.AggiungiElementoTabella('' || i.Targa || '');
                gui.AggiungiElementoTabella('' || i.Cilindrata || '');
                gui.AggiungiElementoTabella('' || i.Nposti || '');
                gui.AggiungiElementoTabella('' || i.Npersonedisabili || '');
                gui.AggiungiElementoTabella('' || i.KM || '');
                gui.AggiungiElementoTabella('' || i.Stato || '');
                gui.AggiungiElementoTabella('' || i.Tariffa || '€' || '');
                gui.ChiudiRigaTabella();
            end if;
            end loop;

        gui.CHIUDITABELLA();
        end if;

        --TAXI LUSSO
        if tipoTaxi = 'Lusso' then
            gui.APRITABELLA(gui.StringArray('Referente', 'Targa', 'Cilindrata', 'Posti',
                                'Chilometraggio', 'Stato', 'Tariffa', 'Optionals', ' '));
            for i in (SELECT t.*
                    FROM TAXI t
                    LEFT JOIN TAXILUSSO tl ON t.IDtaxi = tl.FK_Taxi
                    where (tl.FK_TAXI = t.IDTAXI)
                    and (t.FK_Referente =  t_fkreferente or t_fkreferente is null)
                    and (UPPER(replace(t.Targa, '','')) LIKE '%' || (UPPER(replace(t_targa,'',''))) || '%' or t_targa is null)
                    and (t.CILINDRATA = t_cilindrata or t_cilindrata is null)
                    and (t.NPOSTI = t_nposti or t_nposti is null)
                    and (t.KM = t_km or t_km is null)
                    and (LOWER(replace(t.STATO, '', '')) = LOWER(replace(t_stato,'','')) or t_stato is null)
                    and (t.TARIFFA = t_tariffa or t_tariffa is null))
            loop
            if t_IDtaxi = i.IDTAXI then
                gui.AggiungiRigaTabella();

                SELECT d.Nome, d.Cognome INTO NomeAutista, CognomeAutista
                FROM DIPENDENTI d
                WHERE d.Matricola = i.FK_Referente;

                gui.AggiungiElementoTabella('' || NomeAutista || ' ' || CognomeAutista ||'');
                gui.AggiungiElementoTabella('' || i.Targa || '');
                gui.AggiungiElementoTabella('' || i.Cilindrata || '');
                gui.AggiungiElementoTabella('' || i.Nposti || '');
                gui.AggiungiElementoTabella('' || i.KM || '');
                gui.AggiungiElementoTabella('' || i.Stato || '');
                gui.AggiungiElementoTabella('' || i.Tariffa || '€' || '');
                gui.AggiungiBottoneTabella('Visualizza', url => u_root || '.visualizzaOptionals?id_ses=' || id_ses || '' || chr(38) || 'o_IDtaxi=' || i.IDtaxi);
                gui.ChiudiRigaTabella();
            end if;
            end loop;

        gui.CHIUDITABELLA();
        end if;

        gui.ACAPO(2);
        gui.CHIUDIPAGINA();

    end visualizzaUnTaxi;

    PROCEDURE modificaTaxi(
        id_ses in SessioniDipendenti.IDSessione%type,
        t_idtaxi in TAXI.IDTAXI%type default null,
        t_tipo in varchar2 default null,
        t_accessibili in TAXIACCESSIBILE.NPERSONEDISABILI%type default null,
        t_fkreferente in TAXI.FK_REFERENTE%type default null,
        t_targa in TAXI.TARGA%type default null,
        t_cilindrata in TAXI.CILINDRATA%type default null,
        t_nposti in TAXI.NPOSTI%type default null,
        t_km in TAXI.KM%type default null,
        t_stato in TAXI.STATO%type default null,
        t_tariffa in TAXI.TARIFFA%type default null,
        message in varchar default ''
    ) is
    s BOOLEAN;
    oldKmTaxi TAXI.KM%type;
    kmTaxi TAXI.KM%type;
    referenteTaxi TAXi.FK_REFERENTE%type;
    targaTaxi TAXI.TARGA%type;
    cilindrataTaxi TAXI.CILINDRATA%type;
    npostiTaxi TAXI.NPOSTI%type;
    naccessibiliTaxi TAXIACCESSIBILE.NPERSONEDISABILI%type;
    statoTaxi TAXI.STATO%type;
    tariffaTaxi TAXI.TARIFFA%type;
    begin

        SELECT t.Targa INTO targaTaxi
        FROM TAXI t
        WHERE t.IDtaxi = t_idtaxi;

        IF sessionhandler.getruolo(id_ses)='Autista' THEN
            g2s.INITIALIZATION(id_ses,'modificaTaxi', 'Modifica chilometraggio del taxi con targa: ' || targaTaxi);

            gui.ACAPO();
            gui.BOTTONEAGGIUNGI(testo => 'BACK to Visualizza Taxi', url => u_root || '.visualizzaTaxi?id_ses='||id_ses);
            gui.ACAPO();

            -- PopUp per feedback
            IF message IS NOT NULL THEN
                gui.AggiungiPopup(successo => false, testo => message);
                gui.aCapo();
            END IF;

            -- KM CHE MODIFICO
            SELECT t.KM INTO kmTaxi
            FROM TAXI t
            WHERE t.IDtaxi = t_idtaxi;

            -- KM VCCHI PER CONTROLLO FUTURO
            SELECT t.KM INTO oldKmTaxi
            FROM TAXI t
            WHERE t.IDtaxi = t_idtaxi;

            --FORM AUTISTA
            gui.AggiungiForm(name=>'Modifica Taxi', url=> u_root || '.checkModificheTaxi');

            gui.aCapo();
            gui.AggiungiLabel('t_km','Numero km:');
            gui.AggiungiInput(tipo => 'number', nome => 't_km', value => kmTaxi, placeholder => 'Numero chilometri' || kmTaxi, required => true);
            gui.aggiungiSelezioneSingola(elementi => gui.stringArray('Disponibile', 'Non disponibile', 'Occupato', 'Prenotato','Fermo'), valoreEffettivo => gui.stringArray('disponibile', 'non disponibile', 'occupato', 'prenotato','fermo'), titolo => 'Seleziona Stato', ident => 't_stato', optionSelected => t_stato, firstNull => false);

            gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 'id_ses', value => id_ses);
            gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 't_idtaxi', value => t_idtaxi);
            gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 't_oldKm', value => oldKmTaxi);
            gui.AggiungiCampoFormHidden(tipo => 'text', nome => 't_stato', value => t_stato);

        END IF;

        -- FORM MANAGER
        IF sessionhandler.getruolo(id_ses)='Manager' THEN
            g2s.INITIALIZATION(id_ses,'modificaTaxi', 'Modifica i dati del taxi con targa: ' || targaTaxi);

            gui.ACAPO();
            gui.BOTTONEAGGIUNGI(testo => 'BACK to Visualizza Taxi', url => u_root || '.visualizzaTaxi?id_ses='||id_ses);
            gui.ACAPO();

            -- PopUp per feedback
            IF message IS NOT NULL THEN
                gui.AggiungiPopup(successo => false, testo => message);
                gui.aCapo();
            END IF;

            -- QUERY PER POPOLARE IL FORM
            SELECT t.FK_Referente, t.Targa, t.Cilindrata, t.Nposti, t.KM, t.Stato, t.Tariffa INTO referenteTaxi, targaTaxi, cilindrataTaxi, npostiTaxi, kmTaxi, statoTaxi, tariffaTaxi
            FROM TAXI t
            WHERE t.IDtaxi = t_idtaxi;

            -- KM VECCHI PER CONTROLLO FUTURO
            SELECT t.KM INTO oldKmTaxi
            FROM TAXI t
            WHERE t.IDtaxi = t_idtaxi;

            gui.AggiungiForm(name=>'Modifica Taxi', url=> u_root || '.checkModificheTaxi');

            gui.acapo();
            gui.aggiungiSelezioneSingola(elementi => g2S.listAutisti, valoreEffettivo => g2S.listIDAutisti, titolo => 'Seleziona Referente', ident => 't_fkreferente', optionSelected => referenteTaxi, firstNull => false);
            gui.aggiungilabel('t_targa', 'Targa:');
            gui.aggiungiinput(tipo => 'text', nome => 't_targa', value => targaTaxi, placeholder => 'Targa', required => true);
            gui.aggiungilabel('t_cilindrata', 'Cilindrata:');
            gui.aggiungiinput(tipo => 'number', nome => 't_cilindrata', value => cilindrataTaxi, placeholder => 'Cilindrata', required => true);
            gui.aggiungilabel('t_nposti', 'Numero Posti:');
            gui.aggiungiinput(tipo => 'number', nome => 't_nposti', value => npostiTaxi, placeholder => 'Numero Posti', required => true);
            IF t_tipo = 'ACCESSIBILE' THEN

                -- QUERY PER PRENDERE IL NUMERO DI POSTI PER DISABILI
                SELECT ts.NpersoneDisabili INTO naccessibiliTaxi
                FROM TAXIACCESSIBILE ts
                WHERE ts.FK_Taxi = t_idtaxi;

                gui.aggiungilabel('t_accessibili', 'Numero Posti Disabili:');
                gui.aggiungiinput(tipo => 'number', nome => 't_accessibili', value => naccessibiliTaxi, placeholder => 'Numero Posti Disabili', required => true);

            END IF;
            gui.AggiungiLabel('t_km','Numero km:');
            gui.AggiungiInput(tipo => 'number', nome => 't_km', value => kmTaxi, placeholder => 'Numero chilometri', required => true);
            gui.AggiungiLabel('t_tariffa','Tariffa:');
            gui.AggiungiInput(tipo => 'number', nome => 't_tariffa', value => tariffaTaxi, placeholder => 'Tariffa', required => true);
            gui.aggiungiSelezioneSingola(elementi => gui.stringArray('Disponibile', 'Non disponibile', 'Occupato', 'Prenotato','Fermo'), valoreEffettivo => gui.stringArray('disponibile', 'non disponibile', 'occupato', 'prenotato','fermo'), titolo => 'Seleziona Stato', ident => 't_stato', optionSelected => t_stato, firstNull => false);
            gui.acapo(3);
            gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 'id_ses', value => id_ses);
            gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 't_idtaxi', value => t_idtaxi);
            gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 't_oldKm', value => oldKmTaxi);
            gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 't_stato', value => t_stato);
            gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 't_tipo', value => t_tipo);
        END IF;

        gui.aggiungiBottoneSubmit(value => 'Modifica');
        gui.chiudiForm();

        gui.ACAPO(2);
        gui.CHIUDIPAGINA();

    end modificaTaxi;

    PROCEDURE checkModificheTaxi(
        id_ses in SessioniDipendenti.IDSessione%type,
        t_idtaxi in TAXI.IDTAXI%type default null,
        t_accessibili in TAXIACCESSIBILE.NPERSONEDISABILI%type default null,
        t_fkreferente in TAXI.FK_REFERENTE%type default null,
        t_targa in TAXI.TARGA%type default null,
        t_cilindrata in TAXI.CILINDRATA%type default null,
        t_nposti in TAXI.NPOSTI%type default null,
        t_km in TAXI.KM%type default null,
        t_oldKm in TAXI.KM%type default null,
        t_stato in TAXI.STATO%type default null,
        t_tariffa in TAXI.TARIFFA%type default null,
        t_tipo in varchar2 default null
    ) is
    nTarga NUMBER(1);
    begin

        IF sessionhandler.getruolo(id_ses)='Manager' THEN

            -- RICAVO IL NUMERO DI TARGHE UGUALI PER CONTROLLO
            SELECT COUNT(*) INTO nTarga
            FROM TAXI t
            WHERE t.TARGA = t_targa;

            -- CHECK REFERTENTE
            IF t_fkreferente IS NOT NULL AND g2s.checkMatricola(t_fkreferente) THEN

                -- CHECK CHILOMETRI
                IF t_km < t_oldKm THEN
                    gui.reindirizza(link || u_root || '.modificaTaxi?id_ses=' || id_ses || '' || chr(38) || 't_idtaxi=' || t_idtaxi || '' || chr(38) || 't_tipo=' || t_tipo || '' || chr(38) || 'message=Chilometraggio%20inferiore%20al%20precedente');
                END IF;
                IF t_km > 999999 THEN
                    gui.reindirizza(link || u_root || '.modificaTaxi?id_ses=' || id_ses || '' || chr(38) || 't_idtaxi=' || t_idtaxi || '' || chr(38) || 't_tipo=' || t_tipo || '' || chr(38) || 'message=Chilometraggio%20superiore%20ai%20limiti');
                END IF;

                -- CHECK TARGA
                IF t_targa IS NOT NULL AND LENGTH(t_targa) = 7 AND nTarga < 2 THEN

                    -- CHECK CILINDRATA
                    IF t_cilindrata IS NOT NULL AND g2s.checkCilindrata(t_cilindrata, t_fkreferente) AND (t_cilindrata > 0 AND t_cilindrata <= 9999) THEN

                        -- CHECK NPOSTI
                        IF t_nposti IS NOT NULL AND (t_nposti > 0 AND t_nposti <= 9) THEN

                                -- CHECK TARIFFA
                                IF t_tariffa IS NOT NULL AND (t_tariffa > 0 AND t_tariffa <= 999) THEN

                                    -- CHECK POSTI DISABILI
                                    IF t_accessibili IS NOT NULL THEN

                                        IF t_accessibili > 0 AND t_accessibili <= 9 THEN
                                            -- CHECK SUPERATI (TAXI ACCESSIBILE)
                                            gui.reindirizza(link || u_root || '.updateTaxi?id_ses=' || id_ses || '' || chr(38) || 't_idtaxi=' || t_idtaxi || '' || chr(38) || 't_km=' || t_km || '' || chr(38) || 't_fkreferente=' || t_fkreferente || '' || chr(38) || 't_targa=' || t_targa || '' || chr(38) || 't_cilindrata=' || t_cilindrata || '' || chr(38) || 't_nposti=' || t_nposti || '' || chr(38) || 't_tariffa=' || t_tariffa || '' || chr(38) || 't_accessibili=' || t_accessibili || '' || chr(38) || 't_stato=' || t_stato || '' || chr(38) || 't_tipo=' || t_tipo);
                                        ELSE
                                            gui.reindirizza(link || u_root || '.modificaTaxi?id_ses=' || id_ses || '' || chr(38) || 't_idtaxi=' || t_idtaxi || '' || chr(38) || 't_tipo=' || t_tipo || '' || chr(38) || 'message=Posti%20accessibili%20non%20validi');
                                        END IF;

                                    ELSE
                                        -- CHECK SUPERATI (TAXI STANDARD/LUSSO)
                                        gui.reindirizza(link || u_root || '.updateTaxi?id_ses=' || id_ses || '' || chr(38) || 't_idtaxi=' || t_idtaxi || '' || chr(38) || 't_km=' || t_km || '' || chr(38) || 't_fkreferente=' || t_fkreferente || '' || chr(38) || 't_targa=' || t_targa || '' || chr(38) || 't_cilindrata=' || t_cilindrata || '' || chr(38) || 't_nposti=' || t_nposti || '' || chr(38) || 't_tariffa=' || t_tariffa || '' || chr(38) || 't_stato=' || t_stato || '' || chr(38) || 't_tipo=' || t_tipo);
                                    END IF;

                                ELSE
                                    gui.reindirizza(link || u_root || '.modificaTaxi?id_ses=' || id_ses || '' || chr(38) || 't_idtaxi=' || t_idtaxi || '' || chr(38) || 't_tipo=' || t_tipo || '' || chr(38) || 'message=Tariffa%20non%20valida');
                            END IF;
                            
                        ELSE
                            gui.reindirizza(link || u_root || '.modificaTaxi?id_ses=' || id_ses || '' || chr(38) || 't_idtaxi=' || t_idtaxi || '' || chr(38) || 't_tipo=' || t_tipo || '' || chr(38) || 'message=Numero%20posti%20non%20valido');
                        END IF;

                    ELSE
                        gui.reindirizza(link || u_root || '.modificaTaxi?id_ses=' || id_ses || '' || chr(38) || 't_idtaxi=' || t_idtaxi || '' || chr(38) || 't_tipo=' || t_tipo || '' || chr(38) || 'message=Cilindrata%20non%20valida');
                    END IF;

                ELSE
                    gui.reindirizza(link || u_root || '.modificaTaxi?id_ses=' || id_ses || '' || chr(38) || 't_idtaxi=' || t_idtaxi || '' || chr(38) || 't_tipo=' || t_tipo || '' || chr(38) || 'message=Targa%20già%20esistente%20o%20non%20valida');
                END IF;

            ELSE
                gui.reindirizza(link || u_root || '.modificaTaxi?id_ses=' || id_ses || '' || chr(38) || 't_idtaxi=' || t_idtaxi || '' || chr(38) || 't_tipo=' || t_tipo || '' || chr(38) || 'message=Matricola%20referente%20non%20valida%20o%20non%20esistente');
            END IF;

        END IF;

        IF sessionhandler.getruolo(id_ses)='Autista' THEN
            -- CHECK CHILOMETRI PER AUTISTA
            IF t_oldKm > t_km THEN
                gui.reindirizza(link || u_root || '.modificaTaxi?id_ses=' || id_ses || '' || chr(38) || 't_idtaxi=' || t_idtaxi || '' || chr(38) || 'message=Chilometraggio%20inferiore%20al%20precedente');
            ELSE IF t_km > 999999 THEN
                gui.reindirizza(link || u_root || '.modificaTaxi?id_ses=' || id_ses || '' || chr(38) || 't_idtaxi=' || t_idtaxi || '' || chr(38) || 'message=Chilometraggio%20superiore%20ai%20limiti');
            ELSE
                gui.reindirizza(link || u_root || '.updateTaxi?id_ses=' || id_ses || '' || chr(38) || 't_idtaxi=' || t_idtaxi || '' || chr(38) || 't_km=' || t_km || '' || chr(38) || 't_stato=' || t_stato);
            END IF;
            END IF;

        END IF;

    END checkModificheTaxi;

    PROCEDURE updateTaxi (
        id_ses in SessioniDipendenti.IDSessione%type,
        t_idtaxi in TAXI.IDTAXI%type default null,
        t_tipo in varchar2 default null,
        t_accessibili in TAXIACCESSIBILE.NPERSONEDISABILI%type default null,
        t_fkreferente in TAXI.FK_REFERENTE%type default null,
        t_targa in TAXI.TARGA%type default null,
        t_cilindrata in TAXI.CILINDRATA%type default null,
        t_nposti in TAXI.NPOSTI%type default null,
        t_km in TAXI.KM%type default null,
        t_stato in TAXI.STATO%type default null,
        t_tariffa in TAXI.TARIFFA%type default null,
        message in varchar default ''
    ) is
    begin

        SAVEPOINT sp1;
        BEGIN
            -- UPDATE PER AUTISTA
            IF sessionhandler.getruolo(id_ses)='Autista' THEN
                UPDATE TAXI t
                SET t.Km = t_km,
                    t.Stato = t_stato
                WHERE t.IDtaxi = t_idtaxi;
            END IF;

            -- UPDATE PER MANAGER
            IF sessionhandler.getruolo(id_ses)='Manager' THEN

                UPDATE TAXI t
                SET t.FK_Referente = t_fkreferente,
                    t.Targa = UPPER(t_targa),
                    t.Cilindrata = t_cilindrata,
                    t.Nposti = t_nposti,
                    t.Km = t_km,
                    t.Stato = t_stato,
                    t.Tariffa = t_tariffa
                WHERE t.IDtaxi = t_idtaxi;
                IF t_accessibili IS NOT NULL THEN
                    UPDATE TAXIACCESSIBILE ta
                    SET ta.NpersoneDisabili = t_accessibili
                    WHERE ta.FK_Taxi = t_idtaxi;
                END IF;

            END IF;

        COMMIT;

        gui.reindirizza(link || u_root || '.visualizzaTaxi?id_ses=' || id_ses || '' || chr(38) || 'message=Taxi%20modificato%20correttamente');

        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK TO sp1;
                gui.reindirizza(link || u_root || '.modificaTaxi?id_ses=' || id_ses || '' || chr(38) || 't_idtaxi=' || t_idtaxi || '' || chr(38) || 't_tipo=' || t_tipo || '' || chr(38) || 'message=Modifica%20non%20avvenuta%20a%20causa%20di%20un%20errore');
        END;

    END updateTaxi;

    PROCEDURE inserisciTipologiaTaxi(
        id_ses in SessioniDipendenti.IDSessione%type,
        t_tipologia in VARCHAR default 'STANDARD'
    )is
    begin
        IF SessionHandler.getRuolo(id_ses) != 'Manager' THEN
            gui.ApriPagina('inserisciTipologiaTaxi', id_ses);
            gui.AGGIUNGIPOPUP(false,'Non hai il permesso per accedere a questa pagina', costanti.url||'gui.homePage?idSessione='||id_ses);
            return;
        end if;
        g2S.initialization(id_ses,'inserisciTipologiaTaxi','Inserisci la tipologia del taxi');

        gui.ACAPO();
        gui.BOTTONEAGGIUNGI(testo => 'BACK to Visualizza Taxi', url => u_root || '.visualizzaTaxi?id_ses='||id_ses);
        gui.ACAPO();
        -- FORM
        gui.aggiungiForm(name => 'inserisci Tipologia Taxi', url => u_root || '.inserisciTaxi');
            gui.aggiungiSelezioneSingola(elementi => gui.STRINGARRAY('Taxi Standard','Taxi Accessibile','Taxi di Lusso'), valoreeffettivo => gui.STRINGARRAY('STANDARD','ACCESSIBILE','LUSSO'), titolo => 'Scegli la tipologia del taxi', ident => 't_tipologia', optionselected => t_tipologia, firstnull => false);

            gui.AggiungiCampoFormHidden(tipo => 'number', nome => 'id_ses', value => id_ses);

            gui.aggiungiBottoneSubmit(value => 'Continua');
        gui.chiudiForm();

        gui.ACAPO();
        gui.CHIUDIPAGINA();
    end inserisciTipologiaTaxi;

    PROCEDURE inserisciTaxi(
        id_ses in SessioniDipendenti.IDSessione%type,
        t_tipologia in VARCHAR,
        t_referente_matr in Taxi.FK_Referente%type default null,
        t_targa in Taxi.Targa%type default null,
        t_cilindrata in Taxi.Cilindrata%type default null,
        t_nposti in Taxi.Nposti%type default null,
        t_km in Taxi.Km%type default null,
        t_tariffa in Taxi.Tariffa%type default null,
        t_NpersoneDisabili in TaxiAccessibile.NpersoneDisabili%type default null,
        t_IDoptionals in varchar2 default null,
        posMessage in VARCHAR default null,
        negMessage in varchar default null
    )is
    begin

        htp.prn('<script>   const newUrl = "'||u_root||'.inserisciTaxi?id_ses='||id_ses||
                chr(38)||'t_tipologia='||t_tipologia||
                chr(38)||'t_referente_matr='||t_referente_matr||
                chr(38)||'t_targa='||t_targa||
                chr(38)||'t_cilindrata='||t_cilindrata||
                chr(38)||'t_nposti='||t_nposti||
                chr(38)||'t_km='||t_km||
                chr(38)||'t_tariffa='||t_tariffa||
                chr(38)||'t_NpersoneDisabili='||t_NpersoneDisabili||
                chr(38)||'t_IDoptionals='||t_IDoptionals||
                '";
                history.replaceState(null, null, newUrl);</script>');
        g2S.initialization(id_ses,'inserisciTaxi','Inserisci i dati del taxi');

        IF posMessage IS NOT NULL THEN
            gui.AggiungiPopup(successo => true, testo => posMessage);
            gui.ACAPO();
        else
            IF negMessage IS NOT NULL THEN
                gui.AggiungiPopup(successo => false, testo => negMessage);
                gui.ACAPO();
            end if;
        end if;


        gui.ACAPO();
        gui.BOTTONEAGGIUNGI(testo => 'BACK to Inserisci Tipologia', url => u_root || '.inserisciTipologiaTaxi?' || 'id_ses='|| id_ses || '' || chr(38) || 't_tipologia=' || t_tipologia);
        gui.ACAPO();

        IF t_tipologia = 'LUSSO' THEN
            gui.ACAPO(2);
            gui.BOTTONEAGGIUNGI(testo => 'Inserisci NEW Optional', url => u_root || '.inserisciOptional?'
                                                                                 || 'id_ses='|| id_ses
                                                                      || chr(38) || 't_tipologia=' || t_tipologia
                                                                      || chr(38) || 't_referente_matr='||t_referente_matr
                                                                      || chr(38) || 't_targa=' || t_targa
                                                                      || chr(38) || 't_cilindrata=' || t_cilindrata
                                                                      || chr(38) || 't_nposti=' || t_nposti
                                                                      || chr(38) || 't_km=' || t_km
                                                                      || chr(38) || 't_tariffa=' || t_tariffa
                                                                      || chr(38) || 't_IDoptionals=' || t_IDoptionals);
            gui.ACAPO();
        END IF;

        gui.aggiungiForm(name => 'Registrazione Taxi', url => u_root||'.checkTaxi');
        gui.aggiungiGruppoInput;
            gui.aggiungiSelezioneSingola(elementi => g2S.listAutisti, valoreeffettivo => g2S.listIDAutisti, titolo => 'Referente', optionselected => t_referente_matr, ident => 't_referente_matr');

            gui.AggiungiLabel('targa','Targa:');
            gui.AggiungiInput(tipo => 'text', nome => 't_targa', value => t_targa, placeholder => 'Targa', required => true, pattern => '[a-zA-Z]{2}[0-9]{3}[a-zA-Z]{2}', ident => 't_targa');

            gui.AggiungiLabel('cilindrata','Cilindrata:');
            gui.AggiungiInput(tipo => 'number', nome => 't_cilindrata', value => t_cilindrata, placeholder => 'Cilindrata', required => true, minimo => 0, massimo => 9999, ident => 't_cilindrata');

            IF t_tipologia = 'ACCESSIBILE' THEN
                gui.AggiungiLabel('nposti','Numero Posti:');
                gui.AggiungiInput(tipo => 'number', nome => 't_nposti', value => t_nposti, placeholder => 'Numero Posti', required => true, minimo => 0, massimo => 3, ident => 't_nposti');

                gui.AggiungiLabel('NpersoneDisabili','Numero dei posti per persone disabili:');
                gui.AggiungiInput(tipo => 'number', nome => 't_NpersoneDisabili', value => t_NpersoneDisabili, placeholder => 'Numero posti per disabili', required => true, minimo => 1, massimo => 2, ident => 't_NpersoneDisabili');
            ELSE
                gui.AggiungiLabel('nposti','Numero Posti:');
                gui.AggiungiInput(tipo => 'number', nome => 't_nposti', value => t_nposti, placeholder => 'Numero Posti', required => true, minimo => 1, massimo => 8, ident => 't_nposti');
            END IF;

            gui.AggiungiLabel('km','Km:');
            gui.AggiungiInput(tipo => 'number', nome => 't_km', value => t_km, placeholder => 'Km', required => true, minimo => 0, massimo => 999999, ident => 't_km');

            gui.AggiungiLabel('tariffa','Tariffa:');
            gui.AggiungiInput(tipo => 'number', nome => 't_tariffa', value => t_tariffa, placeholder => 'Tariffa', required => true, minimo => 0.01, step => '.01', massimo => 999.99, ident => 't_tariffa');

            IF t_tipologia = 'LUSSO' THEN
                gui.AggiungiCampoFormHidden(tipo => 'text', nome => 't_IDoptionals');
                gui.aggiungiSelezioneMultipla(testo => 'Seleziona Optional', placeholder => 'Seleziona Optional', ids => g2S.listIdOptionals ,names => g2S.listOptionals, hiddenParameter => 't_IDoptionals', parametriSelezionati => g2S.splitString(t_IDoptionals,';'), ident => 't_IDoptionals');
            END IF;

            gui.AggiungiCampoFormHidden(tipo => 'text', nome => 't_tipologia', value => t_tipologia);
            gui.AggiungiCampoFormHidden(tipo => 'number', nome => 'id_ses', value => id_ses);
            gui.aggiungiBottoneSubmit(value => 'Inserisci');
        gui.chiudiGruppoInput;
        gui.chiudiForm();

        gui.ACAPO();
        gui.CHIUDIPAGINA();

    end inserisciTaxi;

    PROCEDURE checkTaxi(
        id_ses in SessioniDipendenti.IDSessione%type,
        t_tipologia in VARCHAR,
        t_referente_matr in Taxi.FK_Referente%type,
        t_targa in Taxi.Targa%type,
        t_cilindrata in Taxi.Cilindrata%type,
        t_nposti in Taxi.Nposti%type,
        t_km in Taxi.Km%type,
        t_tariffa in Taxi.Tariffa%type,
        t_NpersoneDisabili in TaxiAccessibile.NpersoneDisabili%type default null,
        t_IDoptionals in varchar2 default null
    )is
        message varchar(30);
    begin
        IF t_referente_matr IS NOT NULL AND g2S.checkMatricola(t_referente_matr) THEN
            IF t_targa IS NOT NULL AND g2S.checkTarga(t_targa) THEN
                IF t_cilindrata IS NOT NULL AND g2S.checkCilindrata(t_cilindrata, t_referente_matr) THEN
                    IF t_nposti IS NOT NULL THEN
                        IF t_km IS NOT NULL  THEN
                            IF t_tariffa IS NOT NULL  THEN
                                IF t_tipologia IS NOT NULL THEN
                                    CASE t_tipologia
                                        WHEN 'STANDARD' THEN
                                            gui.REINDIRIZZA(link || ''||u_user||'.gruppo4.PrimaRevisione?idSessione='||id_ses||
                                                '' ||chr(38) || 't_referente_matr='||t_referente_matr||
                                                '' ||chr(38) || 't_targa='||t_targa||
                                                '' ||chr(38) || 't_cilindrata='||t_cilindrata||
                                                '' ||chr(38) || 't_nposti='||t_nposti||
                                                '' ||chr(38) || 't_km='||t_km||
                                                '' ||chr(38) || 't_tariffa='||t_tariffa||
                                                '' ||chr(38) || 't_tipologia='||t_tipologia);
                                            return;
                                        WHEN 'ACCESSIBILE' THEN
                                            IF t_NpersoneDisabili IS NOT NULL THEN
                                                gui.REINDIRIZZA(link || ''||u_user||'.gruppo4.PrimaRevisione?idSessione='||id_ses||
                                                    '' ||chr(38) || 't_referente_matr='||t_referente_matr||
                                                    '' ||chr(38) || 't_targa='||t_targa||
                                                    '' ||chr(38) || 't_cilindrata='||t_cilindrata||
                                                    '' ||chr(38) || 't_nposti='||t_nposti||
                                                    '' ||chr(38) || 't_km='||t_km||
                                                    '' ||chr(38) || 't_tariffa='||t_tariffa||
                                                    '' ||chr(38) || 't_NpersoneDisabili='||t_NpersoneDisabili||
                                                    '' ||chr(38) || 't_tipologia='||t_tipologia);
                                                return;
                                            ELSE
                                                message := 'checkAccessibile FALLITO';
                                            END IF;
                                        WHEN 'LUSSO' THEN
                                             gui.REINDIRIZZA(link || ''||u_user||'.gruppo4.PrimaRevisione?idSessione='||id_ses||
                                                '' ||chr(38) || 't_referente_matr='||t_referente_matr||
                                                '' ||chr(38) || 't_targa='||t_targa||
                                                '' ||chr(38) || 't_cilindrata='||t_cilindrata||
                                                '' ||chr(38) || 't_nposti='||t_nposti||
                                                '' ||chr(38) || 't_km='||t_km||
                                                '' ||chr(38) || 't_tariffa='||t_tariffa||
                                                '' ||chr(38) || 't_IDoptionals='||t_IDoptionals||
                                                '' ||chr(38) || 't_tipologia='||t_tipologia);
                                             return;
                                        ELSE
                                            message := 'checkTipologia FALLITO';
                                    END CASE;
                                ELSE
                                    message := 'checkTipologiaIF FALLITO';
                                END IF;
                            ELSE
                                message := 'checkTariffa FALLITO';
                            END IF;
                        ELSE
                            message := 'checKm FALLITO';
                        END IF;
                    ELSE
                        message := 'checkNposti FALLITO';
                    END IF;
                ELSE
                    message := 'checkCilindrata FALLITO';
                END IF;
            ELSE
                message := 'checkTarga FALLITO';
            END IF;
        ELSE
            message := 'checkMatricola FALLITO';
        END IF;
        gui.REINDIRIZZA(link || ''||u_root||'.inserisciTaxi?id_ses='||id_ses||
                chr(38) || 't_referente_matr='||t_referente_matr||
                chr(38) || 't_targa='||t_targa||
                chr(38) || 't_cilindrata='||t_cilindrata||
                chr(38) || 't_nposti='||t_nposti||
                chr(38) || 't_km='||t_km||
                chr(38) || 't_tariffa='||t_tariffa||
                chr(38) || 'negMessage='||message||
                chr(38) || 't_NpersoneDisabili='||t_NpersoneDisabili||
                chr(38) || 't_IDoptionals='||t_IDoptionals||
                chr(38) || 't_tipologia='||t_tipologia);
    end checkTaxi;

    PROCEDURE insertTaxiRevisione(
        id_ses in SessioniDipendenti.IDSessione%type,
        t_tipologia in VARCHAR,
        t_referente_matr in Taxi.FK_Referente%type,
        t_targa in Taxi.Targa%type,
        t_cilindrata in Taxi.Cilindrata%type,
        t_nposti in Taxi.Nposti%type,
        t_km in Taxi.Km%type,
        t_tariffa in Taxi.Tariffa%type,
        t_NpersoneDisabili in TaxiAccessibile.NpersoneDisabili%type default null,
        t_IDoptionals in varchar2 default null,
        -- REVISIONE
        DataRev in varchar2,
        ScadRev in varchar2,
        AzioneRev in AZIONICORRETTIVE.Azione%type
    )is
    b boolean;
    idTaxiVal Taxi.IDtaxi%type;
    begin
        savepoint sp1;

        -- Inizia la transazione
        BEGIN
            idTaxiVal := seq_IDtaxi.NEXTVAL;
            INSERT INTO Taxi (IDtaxi, FK_Referente, Targa, Cilindrata, Nposti, KM, Stato, Tariffa)
                VALUES (idTaxiVal, t_referente_matr, UPPER(t_targa), t_cilindrata, t_nposti, t_km, 'fermo', t_tariffa);

            CASE t_tipologia
                WHEN 'STANDARD' THEN
                    INSERT INTO TAXISTANDARD (FK_Taxi) VALUES (idTaxiVal);
                WHEN 'ACCESSIBILE' THEN
                    INSERT INTO TAXIACCESSIBILE (FK_Taxi, NpersoneDisabili) VALUES (idTaxiVal, t_NpersoneDisabili);
                WHEN 'LUSSO' THEN
                    INSERT INTO TAXILUSSO (FK_Taxi) VALUES (idTaxiVal);
                    -- Inserimento degli optional, se presenti
                    IF t_IDoptionals IS NOT NULL THEN
                        FOR o IN (
                            SELECT REGEXP_SUBSTR(t_IDoptionals, '[^;]+', 1, LEVEL) AS optional_id
                            FROM DUAL
                            CONNECT BY REGEXP_SUBSTR(t_IDoptionals, '[^;]+', 1, LEVEL) IS NOT NULL
                        ) LOOP
                            INSERT INTO POSSIEDETAXILUSSO (FK_TaxiLusso, FK_Optionals)
                            VALUES (idTaxiVal, o.optional_id);
                        END LOOP;
                    END IF;

            END CASE;

            -- Esegue la procedura di inserimento della prima revisione
            b := gruppo4.inserisciPrimaRev(DataRev,ScadRev,AzioneRev, idTaxiVal);

            IF NOT b THEN
                -- Se c'è un errore, esegue il rollback alla savepoint e gestisce l'errore
                rollback to sp1;
                gui.REINDIRIZZA(link || ''||u_root||'.visualizzaTaxi?id_ses='||id_ses||''||chr(38)||'negMessage=Inserimento%20non%20avvenuto%20a%20causa%20di%20un%20errore: '||SQLERRM);
            ELSE
                -- Se tutto va bene, conferma la transazione
                COMMIT;
                gui.REINDIRIZZA(link || ''||u_root||'.visualizzaTaxi?id_ses='||id_ses||''||chr(38)||'message=Inserimento%20avvenuto%20con%20successo');
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                -- Se c'è un errore, esegue il rollback alla savepoint e gestisce l'errore
                rollback to sp1;
                gui.REINDIRIZZA(link ||u_root||'.visualizzaTaxi?id_ses='||id_ses||chr(38)||'negMessage=Inserimento%20non%20avvenuto%20a%20causa%20di%20un%20errore: '||SQLERRM);
        END;
    END insertTaxiRevisione;

----------------------  OPTIONALS   ----------------------
    procedure visualizzaOptionals(
        id_ses in SessioniDipendenti.IDSessione%type,
        o_Nome in Optionals.Nome%type default null,
        o_IDtaxi in Taxi.IDtaxi%type default null,
        o_Data_min in varChar2 default null,
        o_Data_max in varChar2 default null,
        o_Ora_min in varChar2 default null,
        o_Ora_max in varChar2 default null,
        negMessage in varchar default null,
        posMessage in varchar default null
    ) IS
    head gui.STRINGARRAY;
    o_Targa Taxi.Targa%type;
    nOptionalPar int;
    nOptionalTot int;
    percentuale DECIMAL(5,2);
    strNum VARCHAR(10000);
    strPerc VARCHAR(10000);
    strNome VARCHAR(10000);
    begin
        IF SessionHandler.getRuolo(id_ses) = 'Operatore' THEN
            gui.ApriPagina('visualizzaOptionals', id_ses);
            gui.AGGIUNGIPOPUP(false,'Non hai il permesso per accedere a questa pagina', costanti.url||'gui.homePage?idSessione='||id_ses);
            return;
        end if;
        htp.prn('<script>   const newUrl = "'||u_root||'.visualizzaOptionals?id_ses='||id_ses||
                chr(38)||'o_Nome='||o_Nome||
                chr(38)||'o_IDtaxi='||o_IDtaxi||
                chr(38)||'o_Data_min='||o_Data_min||
                chr(38)||'o_Data_max='||o_Data_max||
                chr(38)||'o_Ora_min='||o_Ora_min||
                chr(38)||'o_Ora_max='||o_Ora_max||'";
                history.replaceState(null, null, newUrl);</script>');

        IF o_IDtaxi IS NULL THEN
            g2S.initialization(id_ses,'visualizzaOptionals','Visualizza Optionals');
        ELSE
            SELECT Targa into o_Targa FROM Taxi t WHERE t.IDtaxi = o_IDtaxi;
            g2S.initialization(id_ses,'visualizzaOptionals', 'Visualizza Optionals del taxi: ' || o_Targa);
        end if;

        IF posMessage IS NOT NULL THEN
            gui.AggiungiPopup(successo => true, testo => posMessage);
            gui.ACAPO();
        ELSE
            IF negMessage IS NOT NULL THEN
                gui.AggiungiPopup(successo => false, testo => negMessage);
                gui.ACAPO();
            end if;
        end if;

        If o_IDtaxi IS NOT NULL THEN
            gui.acapo();
            gui.BOTTONEAGGIUNGI(testo => 'BACK to Visualizza', url => u_root || '.visualizzaTaxi?id_ses='||id_ses);
            gui.ACAPO();
            gui.ACAPO();
        end if;

        If SessionHandler.getRuolo(id_ses) = 'Manager' OR
            ( (SessionHandler.getRuolo(id_ses) = 'Autista' AND
               g2S.isReferente(SessionHandler.getIDuser(id_ses), o_IDtaxi)) ) THEN
            gui.acapo();
            gui.aCapo();
            gui.BOTTONEAGGIUNGI(testo => 'Aggiungi Optional', url => u_root || '.inserisciOptional?id_ses='||id_ses||'' || chr(38)||'o_IDtaxi='||o_IDtaxi);
            gui.ACAPO();
        end if;
        -- FILTRO
        gui.ApriFormFiltro(u_root || '.visualizzaOptionals');
        gui.AggiungiCampoFormFiltro(tipo => 'text', nome => 'o_Nome', value => o_Nome, placeholder => 'Nome');
        gui.AggiungiCampoFormHidden(tipo => 'number', nome => 'id_ses', value => id_ses);
        gui.AggiungiCampoFormHidden(tipo => 'number', nome => 'o_IDtaxi', value => o_IDtaxi);
        gui.AggiungiCampoFormHidden(tipo => 'date', nome => 'o_Data_min', value => o_Data_min);
        gui.AggiungiCampoFormHidden(tipo => 'date', nome => 'o_Data_max', value => o_Data_max);
        gui.AggiungiCampoFormHidden(tipo => 'time', nome => 'o_Ora_min', value => o_Ora_min);
        gui.AggiungiCampoFormHidden(tipo => 'time', nome => 'o_Ora_max', value => o_Ora_max);
        gui.AggiungiCampoFormFiltro(tipo => 'submit', nome => '', placeholder => 'Filtra');
        gui.chiudiFormFiltro();

        gui.ACAPO();

        -- RESET FILTRO
        g2S.resetFilter(url => '.visualizzaOptionals', id_ses => id_ses, o_IDtaxi => o_IDtaxi, o_Data_min => o_Data_min, o_Data_max => o_Data_max, o_Ora_min => o_Ora_min, o_Ora_max => o_Ora_max);

        -- TABLE
        IF o_IDtaxi IS NULL THEN -- quando ho la visualizzazione statica

            IF SessionHandler.getRuolo(id_ses) = 'Manager' THEN
                head := gui.StringArray('Nome', 'Percentuale di utilizzo*',' ');
                SELECT count(*) into nOptionalTot
                FROM PRENOTAZIONELUSSO pl, PRENOTAZIONI p
                WHERE p.IDprenotazione = pl.FK_Prenotazione AND
                    ((to_date(o_Data_min, 'YYYY-MM-DD') <= trunc(p.DataOra)) or o_Data_min is null) AND
                    ((to_date(o_Data_max, 'YYYY-MM-DD') >= trunc(p.DataOra)) or o_Data_max is null) AND
                    (o_Ora_min <= to_char(p.DataOra, 'HH24:SS:MI') or o_Ora_min is null) AND
                    (o_Ora_max >= to_char(p.DataOra, 'HH24:SS:MI') or o_Ora_max is null);
                strNome := '';
                strNum := '';
                strPerc := '';
            ELSE
                head := gui.StringArray('Nome');
            end if;
            gui.ApriTabella(head);

            for x in (
                SELECT IDoptionals, Nome
                FROM Optionals
                WHERE LOWER(replace(Optionals.Nome, ' ', '')) LIKE '%'||(LOWER(replace(o_Nome, ' ', '')))||'%' or o_Nome is null
                ORDER BY Nome
            )
            loop
                gui.AggiungiRigaTabella();
                gui.AggiungiElementoTabella(x.Nome  || '');
                IF SessionHandler.getRuolo(id_ses) = 'Manager' THEN
                    strNome := strNome || '"' || x.Nome || '",';
                    SELECT count(*) into nOptionalPar
                    FROM RICHIESTEPRENLUSSO rpl, PRENOTAZIONI p
                    WHERE rpl.FK_Optionals = x.IDoptionals AND
                        p.IDprenotazione = rpl.FK_Prenotazione AND
                        ((to_date(o_Data_min, 'YYYY-MM-DD') <= trunc(p.DataOra)) or o_Data_min is null) AND
                        ((to_date(o_Data_max, 'YYYY-MM-DD') >= trunc(p.DataOra)) or o_Data_max is null) AND
                        (o_Ora_min <= to_char(p.DataOra, 'HH24:SS:MI') or o_Ora_min is null) AND
                        (o_Ora_max >= to_char(p.DataOra, 'HH24:SS:MI') or o_Ora_max is null);
                    IF nOptionalTot > 0 THEN
                        percentuale := (nOptionalPar / nOptionalTot) * 100;
                        strNum := strNum || nOptionalPar || ',';
                        strPerc := strPerc || percentuale || ',';
                        gui.AggiungiElementoTabella(nOptionalPar || '/' || nOptionalTot|| ' = ' || percentuale || ' %');
                    ELSE
                        gui.AggiungiElementoTabella('0 %'); -- Se il totale è zero, la percentuale sarà sempre zero
                        strNum := strNum ||'0,';
                        strPerc := strPerc || '0,';
                    END IF;
                    gui.apriElementoPulsanti;
                    gui.AggiungiPulsanteModifica(gruppo2.u_root || '.modificaOptionals?id_ses='||id_ses|| '' ||chr(38) || 'o_id='||x.IDOptionals);
                    gui.chiudiElementoPulsanti;
                END IF;
                gui.ChiudiRigaTabella();
            end loop;


            gui.ChiudiTabella();
            IF SessionHandler.getRuolo(id_ses) = 'Manager' THEN
                gui.aggiungiParagrafo('*Percentuale di utilizzo = si riferisce alla proporzione delle prenotazioni di lusso che hanno richiesto un particolare optional rispetto al totale delle prenotazioni di lusso.');

                gui.ApriFormFiltro(u_root || '.visualizzaOptionals');
                gui.AggiungiCampoFormFiltro(tipo => 'date', nome => 'o_Data_min', value => o_Data_min, placeholder => 'Data minima');
                gui.AggiungiCampoFormFiltro(tipo => 'date', nome => 'o_Data_max', value => o_Data_max, placeholder => 'Data massima');
                gui.AggiungiCampoFormFiltro(tipo => 'time', nome => 'o_Ora_min', value => o_Ora_min, placeholder => 'Ora minima');
                gui.AggiungiCampoFormFiltro(tipo => 'time', nome => 'o_Ora_max', value => o_Ora_max, placeholder => 'Ora massima');
                gui.AggiungiCampoFormHidden(tipo => 'text', nome => 'o_Nome', value => o_Nome);
                gui.AggiungiCampoFormHidden(tipo => 'number', nome => 'id_ses', value => id_ses);
                gui.AggiungiCampoFormHidden(tipo => 'number', nome => 'o_IDtaxi', value => o_IDtaxi);
                gui.AggiungiCampoFormFiltro(tipo => 'submit', nome => '', placeholder => 'Filtra Statistica');
                gui.chiudiFormFiltro();
                gui.ACAPO();

                g2S.resetFilter(url => '.visualizzaOptionals', id_ses => id_ses, o_IDtaxi => o_IDtaxi, o_Nome => o_Nome, text => 'Reset Statistica');


                gui.AGGIUNGICHART('doughnut', '
                    {
                        "type": "doughnut",
                        "data": {
                            "labels": ['||strNome||'],
                        "datasets": [{
                            "label": "Numero di utilizzo",
                            "data": ['||strNum||']
                        },{
                            "label": "Percentuale di utilizzo",
                            "data": ['||strPerc||']
                        }]
                    },
                    "options": {
                        "responsive": true,
                        "plugins": {
                            "legend": {
                                "position": "top"
                            },
                            "title": {
                                "display": true,
                                "text": "Percentuale di utilizzo degli optionals"
                            }
                        }
                    }
                }');
            END IF;
        ELSE -- quando ho la visualizzazione di un taxi

            gui.aggiungiIntestazione('Optional presenti sulla vettura', 'h2');
            gui.ACAPO();
            IF SessionHandler.getRuolo(id_ses) = 'Manager' THEN
                head := gui.StringArray('Nome', ' ', ' ');
            ELSE
                IF SessionHandler.getRuolo(id_ses) = 'Autista' AND o_IDtaxi IS NOT NULL AND g2S.isReferente(SessionHandler.getIDuser(id_ses), o_IDtaxi) THEN
                    head := gui.StringArray('Nome', ' ');
                ELSE
                    head := gui.StringArray('Nome');
                end if;
            end if;


            gui.ApriTabella(head,'OptionalsPresenti');

            for x in (
                SELECT o.IDoptionals, o.Nome
                FROM Optionals o, POSSIEDETAXILUSSO ptl, TaxiLusso tl, Taxi t
                WHERE (LOWER(replace(o.Nome, ' ', '')) LIKE '%'||(LOWER(replace(o_Nome, ' ', '')))||'%' or o_Nome is null) AND
                    o.IDoptionals = ptl.FK_Optionals AND
                    ptl.FK_TaxiLusso = tl.FK_Taxi AND
                    tl.FK_Taxi = t.IDtaxi AND
                    t.IDtaxi = o_IDtaxi
                ORDER BY Nome
            )
            loop
                gui.AggiungiRigaTabella();
                gui.AggiungiElementoTabella(x.Nome  || '');
                IF SessionHandler.getRuolo(id_ses) = 'Manager' OR (SessionHandler.getRuolo(id_ses) = 'Autista' AND o_IDtaxi IS NOT NULL AND g2S.isReferente(SessionHandler.getIDuser(id_ses), o_IDtaxi)) THEN
                    IF SessionHandler.getRuolo(id_ses) = 'Manager' THEN
                        gui.APRIELEMENTOPULSANTI();
                        gui.AggiungiPulsanteModifica(gruppo2.u_root || '.modificaOptionals?id_ses='||id_ses|| '' ||chr(38) || 'o_id='||x.IDOptionals|| '' ||chr(38) || 'o_IDtaxi='||o_IDtaxi);--da fixare il discorso degli username
                        gui.CHIUDIELEMENTOPULSANTI();
                    END IF;
                    gui.apriElementoPulsanti;
                    gui.AggiungiPulsanteGenerale(testo => 'REMOVE to TAXI',
                                               collegamento => ''''||u_root||'.removeOptionals?id_ses='||id_ses||
                                                      '' ||chr(38) || 'o_Nome='||o_Nome||
                                                      '' ||chr(38) || 'o_IDtaxi='||o_IDtaxi||
                                                      '' ||chr(38) || 'o_IDoptionals='||x.IDOptionals||'''');
                    gui.chiudiElementoPulsanti;

                end if;
                gui.ChiudiRigaTabella();
            end loop;

            gui.ChiudiTabella('OptionalsPresenti');

            gui.ACAPO();
            gui.aggiungiIntestazione('Optional non presenti sulla vettura', 'h2');
            gui.ACAPO();

            gui.ApriTabella(head, 'OptionalsNonPresenti');

            for x in (
                SELECT IDoptionals, Nome
                FROM Optionals
                WHERE (LOWER(replace(Optionals.Nome, ' ', '')) LIKE '%'||(LOWER(replace(o_Nome, ' ', '')))||'%' or o_Nome is null) AND
                    IDoptionals NOT IN (
                        SELECT IDoptionals
                        FROM Optionals o, POSSIEDETAXILUSSO ptl, TaxiLusso tl, Taxi t
                        WHERE (LOWER(replace(o.Nome, ' ', '')) LIKE '%'||(LOWER(replace(o_Nome, ' ', '')))||'%' or o_Nome is null) AND
                            o.IDoptionals = ptl.FK_Optionals AND
                            ptl.FK_TaxiLusso = tl.FK_Taxi AND
                            tl.FK_Taxi = t.IDtaxi AND
                            t.IDtaxi = o_IDtaxi
                        )
                ORDER BY Nome
            )
            loop
                gui.AggiungiRigaTabella();
                gui.AggiungiElementoTabella(x.Nome  || '');
                IF SessionHandler.getRuolo(id_ses) = 'Manager' OR (SessionHandler.getRuolo(id_ses) = 'Autista' AND o_IDtaxi IS NOT NULL AND g2S.isReferente(SessionHandler.getIDuser(id_ses), o_IDtaxi)) THEN
                    IF SessionHandler.getRuolo(id_ses) = 'Manager' THEN
                        gui.APRIELEMENTOPULSANTI();
                        gui.AggiungiPulsanteModifica(gruppo2.u_root || '.modificaOptionals?id_ses='||id_ses|| '' ||chr(38) || 'o_id='||x.IDOptionals|| '' ||chr(38) || 'o_IDtaxi='||o_IDtaxi);--da fixare il discorso degli username
                        gui.CHIUDIELEMENTOPULSANTI();
                    END IF;
                    gui.apriElementoPulsanti;
                    gui.AggiungiPulsanteGenerale(testo => 'ADD to TAXI',
                                               collegamento => ''''||u_root||'.addOptionals?id_ses='||id_ses||
                                                      '' ||chr(38) || 'o_Nome='||o_Nome||
                                                      '' ||chr(38) || 'o_IDtaxi='||o_IDtaxi||
                                                      '' ||chr(38) || 'o_IDoptionals='||x.IDOptionals||'''');
                    gui.chiudiElementoPulsanti;
                end if;
                gui.ChiudiRigaTabella();
            end loop;

            gui.ChiudiTabella('OptionalsNonPresenti');

        END IF;

        gui.ACAPO();
        gui.CHIUDIPAGINA();

    end visualizzaOptionals;

    PROCEDURE addOptionals(
        id_ses in SessioniDipendenti.IDSessione%type,
        o_Nome in Optionals.Nome%type default null,
        o_IDtaxi in Taxi.IDtaxi%type,
        o_IDoptionals in Optionals.IDoptionals%type
    )is
    begin
        savepoint sp1;
        begin
            INSERT INTO POSSIEDETAXILUSSO (FK_TaxiLusso, FK_Optionals) VALUES (o_IDtaxi, o_IDoptionals);
            COMMIT;
            gui.REINDIRIZZA(link || ''
                       ||u_root||'.visualizzaOptionals?id_ses='||id_ses||
                    '' ||chr(38) || 'o_Nome='||o_Nome||
                    '' ||chr(38) || 'o_IDtaxi='||o_IDtaxi||
                    '' ||chr(38) || 'posMessage=Aggiunta avvenuta con successo');
            EXCEPTION
                WHEN OTHERS THEN
                    -- Se c'è un errore, esegue il rollback alla savepoint e gestisce l'errore
                    rollback to sp1;
                    gui.REINDIRIZZA(link || ''
                       ||u_root||'.visualizzaOptionals?id_ses='||id_ses||
                    '' ||chr(38) || 'o_Nome='||o_Nome||
                    '' ||chr(38) || 'o_IDtaxi='||o_IDtaxi||
                    '' ||chr(38) || 'negMessage=Inserimento%20non%20avvenuto%20a%20causa%20di%20un%20errore');
        end;
    end addOptionals;

    PROCEDURE removeOptionals(
        id_ses in SessioniDipendenti.IDSessione%type,
        o_Nome in Optionals.Nome%type default null,
        o_IDtaxi in Taxi.IDtaxi%type default null,
        o_IDoptionals in Optionals.IDoptionals%type default null
    )is
        st Prenotazioni.Stato%type;
    begin
        savepoint sp1;
        BEGIN
            IF g2S.vieneSoddifatta(o_IDtaxi, o_IDoptionals) THEN
                st := 'pendente';
            ELSE
                st := 'rifiutata';
            end if;
            IF g2S.rifiutaPrenotazioni( o_IDtaxi, o_IDoptionals, st) THEN
                DELETE FROM POSSIEDETAXILUSSO ptl WHERE ptl.FK_TaxiLusso = o_IDtaxi AND FK_Optionals = o_IDoptionals;
                COMMIT;
                gui.REINDIRIZZA(link || ''
                           ||u_root||'.visualizzaOptionals?id_ses='||id_ses||
                        '' ||chr(38) || 'o_Nome='||o_Nome||
                        '' ||chr(38) || 'o_IDtaxi='||o_IDtaxi||
                        '' ||chr(38) || 'posMessage=Rimozione avvenuta con successo');
                return;
            END IF;

            rollback to sp1;
            gui.REINDIRIZZA(link || ''
                   ||u_root||'.visualizzaOptionals?id_ses='||id_ses||
                '' ||chr(38) || 'o_Nome='||o_Nome||
                '' ||chr(38) || 'o_IDtaxi='||o_IDtaxi||
                '' ||chr(38) || 'negMessage=Inserimento%20non%20avvenuto%20a%20causa%20di%20un%20errore');
        EXCEPTION
            WHEN OTHERS THEN
                -- Se c'è un errore, esegue il rollback alla savepoint e gestisce l'errore
                rollback to sp1;
                gui.REINDIRIZZA(link || ''
                       ||u_root||'.visualizzaOptionals?id_ses='||id_ses||
                    '' ||chr(38) || 'o_Nome='||o_Nome||
                    '' ||chr(38) || 'o_IDtaxi='||o_IDtaxi||
                    '' ||chr(38) || 'negMessage=Inserimento%20non%20avvenuto%20a%20causa%20di%20un%20errore');
        end;
    end removeOptionals;

    PROCEDURE modificaOptionals(
        id_ses in SessioniDipendenti.IDSessione%type,
        o_id in Optionals.IDOptionals%type default null,
        o_IDtaxi in Taxi.IDtaxi%type default null,
        message in VARCHAR default ''
    )
    is
    optName VARCHAR(50);
    begin

    SELECT op.nome into optName
    FROM OPTIONALS op
    WHERE op.IDOptionals=o_id;

        g2S.initialization(id_ses,'modificaOptionals','Optional ' || optName ||': Modifica i dati');

       IF message IS NOT NULL THEN
            gui.AggiungiPopup(false,message);
            gui.aCapo();
        END IF;

        IF o_IDtaxi IS NULL THEN
            gui.acapo();
            gui.aCapo();
            gui.BOTTONEAGGIUNGI(testo => 'Back to Visualizza Optionals', url => u_root || '.visualizzaOptionals?id_ses='||id_ses||'');
            gui.ACAPO();
        ELSE
            gui.aCapo();
            gui.acapo();
            gui.BOTTONEAGGIUNGI(testo => 'Back to Visualizza Optionals', url => u_root || '.visualizzaOptionals?id_ses='||id_ses||''
            || chr(38) || 'o_IDtaxi='||o_IDtaxi);
            gui.ACAPO();
        END IF;

        gui.aggiungiForm(name => 'Modifica Optional', url => u_root||'.checkOptionals');
        gui.aCapo();
        gui.AggiungiLabel('o_nome','Nome:');
        gui.aCapo();
        gui.aCapo();
        gui.AggiungiInput(tipo => 'text', nome => 'o_nome', value => optName, placeholder => 'Nuovo Nome '|| optName, required => true);

        gui.aCapo();
        gui.aCapo();


        gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 'o_IDtaxi', value => o_IDtaxi);
        gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 'id_ses', value => id_ses);
        gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 'o_id', value => o_id);

        gui.aggiungiBottoneSubmit(value => 'Inserisci Modifica');
        gui.chiudiForm();

        gui.CHIUDIPAGINA();

    end modificaOptionals;

    PROCEDURE checkOptionals(
        id_ses in SessioniDipendenti.IDSessione%type,
        o_nome in Optionals.Nome%type default '',
        o_id in Optionals.IDOptionals%type default null,
        o_IDtaxi in Taxi.IDtaxi%type default null
    )is
    begin
        IF g2s.checkEqualsOldName(o_id,o_nome) THEN
        gui.REINDIRIZZA(link||u_user||'.gruppo2.modificaOptionals?id_ses='||id_ses||
                                                '' ||chr(38) || 'o_id='||o_id ||
                                                '' ||chr(38) || 'o_IDtaxi='||o_IDtaxi ||
                                                '' ||chr(38) || 'message='||'Non hai modificato il nome');
        ELSE IF g2S.checkNomeOptionals(o_nome) THEN
        gui.REINDIRIZZA(link||u_user||'.gruppo2.updateOptionals?id_ses='||id_ses||
                                                '' ||chr(38) || 'o_nome='||o_nome ||
                                                '' ||chr(38) || 'o_id='||o_id ||
                                                '' ||chr(38) || 'o_IDtaxi='||o_IDtaxi);
        ELSE
        gui.REINDIRIZZA(link||u_user||'.gruppo2.modificaOptionals?id_ses='||id_ses||
                                                    '' ||chr(38) || 'o_id='||o_id ||
                                                    '' ||chr(38) || 'o_IDtaxi='||o_IDtaxi ||
                                                    '' ||chr(38) || 'message='||'Esiste già un optional con quel nome, cerca di modificarlo');
        END IF;
        END IF;
    end checkOptionals;

    PROCEDURE updateOptionals(
        id_ses in SessioniDipendenti.IDSessione%type,
        o_nome in Optionals.Nome%type default '',
        o_id in Optionals.IDOptionals%type default null,
        o_IDtaxi in Taxi.IDtaxi%type default null
    )is
    begin
        savepoint sp1;

        BEGIN
            UPDATE OPTIONALS op
            SET op.Nome = o_nome
            WHERE op.IDOptionals = o_id;
            COMMIT;
            gui.REINDIRIZZA(link||u_user||'.gruppo2.visualizzaOptionals?id_ses='||id_ses||
                                                        '' ||chr(38) || 'o_IDtaxi='||o_IDtaxi ||
                                                        '' ||chr(38) || 'posMessage='||'Aggiornamento effettuato con successo');

            EXCEPTION
            WHEN OTHERS THEN
                -- Se c'è un errore, esegue il rollback alla savepoint e gestisce l'errore
                rollback to sp1;
                gui.REINDIRIZZA(link ||u_root||'.modificaOptionals?id_ses='||id_ses||
                                '' ||chr(38) || 'o_id='||o_id ||
                                '' ||chr(38) || 'o_IDtaxi='||o_IDtaxi ||
                                '' ||chr(38)||'message=Modifica non avvenuta a causa di un errore');
        END;
    end updateOptionals;

    PROCEDURE inserisciOptional(
        id_ses in SessioniDipendenti.IDSessione%type,
        o_IDtaxi in Taxi.IDtaxi%type default null,
        o_name in VARCHAR default null,
        t_tipologia in VARCHAR default null,
        t_referente_matr in Taxi.FK_Referente%type default null,
        t_targa in Taxi.Targa%type default null,
        t_cilindrata in Taxi.Cilindrata%type default null,
        t_nposti in Taxi.Nposti%type default null,
        t_km in Taxi.Km%type default null,
        t_tariffa in Taxi.Tariffa%type default null,
        t_IDoptionals in varchar2 default null,
        message in VARCHAR default ''
    )IS
    b BOOLEAN;
    BEGIN
        IF SessionHandler.getRuolo(id_ses) != 'Manager' AND (SessionHandler.getRuolo(id_ses) != 'Autista' OR NOT g2S.isReferente(SessionHandler.getIDuser(id_ses), o_IDtaxi)) THEN
            gui.ApriPagina('visualizzaCorseNonPrenotate', id_ses);
            gui.AGGIUNGIPOPUP(false,'Non hai il permesso per accedere a questa pagina', costanti.url||'gui.homePage?idSessione='||id_ses);
            return;
        end if;

        g2S.initialization(id_ses => id_ses, i_tab => 'inserisciOptional', i_h1 => 'Inserisci il nome optional');

        IF message IS NOT NULL THEN
            gui.AggiungiPopup(false,message);
            gui.aCapo();
        END IF;

        gui.ACAPO();
        IF t_tipologia IS NULL THEN
            gui.BOTTONEAGGIUNGI(testo => 'BACK to visualizzazione optional', url => u_root || '.visualizzaOptionals?id_ses='||id_ses||
                                                    '' ||chr(38) || 'o_IDtaxi='||o_IDtaxi);
        ELSE
            gui.BOTTONEAGGIUNGI(testo => 'BACK to Inserimento taxi', url=>u_root||'.inserisciTaxi?id_ses='||id_ses||
                                '' ||chr(38) || 't_tipologia='||t_tipologia ||
                                '' ||chr(38) || 't_referente_matr='||t_referente_matr ||
                                '' ||chr(38) || 't_targa='||t_targa ||
                                '' ||chr(38) || 't_cilindrata='||t_cilindrata ||
                                '' ||chr(38) || 't_nposti='||t_nposti ||
                                '' ||chr(38) || 't_km='||t_km ||
                                '' ||chr(38) || 't_tariffa='||t_tariffa ||
                                '' ||chr(38) || 't_IDoptionals='||t_IDoptionals);
        END IF;
        gui.ACAPO();

        gui.AggiungiForm(name=>'Inserisci Optional', url=> u_root || '.checkInserimentoOptional');

        gui.aCapo();
        gui.AggiungiLabel('o_name','Nome');
        gui.AggiungiInput(tipo => 'varchar', nome => 'o_name', value => o_name, placeholder => 'Nome', required => true);

        gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 'id_ses', value => id_ses);
        gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 'o_IDtaxi', value => o_IDtaxi);
        gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 't_tipologia', value => t_tipologia);
        gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 't_referente_matr', value => t_referente_matr);
        gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 't_targa', value => t_targa);
        gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 't_cilindrata', value => t_cilindrata);
        gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 't_nposti', value => t_nposti);
        gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 't_km', value => t_km);
        gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 't_tariffa', value => t_tariffa);
        gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 't_IDoptionals', value => t_IDoptionals);
        gui.aCapo();

        gui.aggiungiBottoneSubmit(value => 'Inserisci Optional');
        gui.chiudiForm();

        gui.aggiungiForm(name => 'visualizzaOptionals', url => u_root||'.visualizzaOptionals');
        gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 'id_ses', value => id_ses);
        gui.chiudiForm();
    END inserisciOptional;

    PROCEDURE checkInserimentoOptional(
        id_ses in SessioniDipendenti.IDSessione%type,
        o_IDtaxi in Taxi.IDtaxi%type default null,
        o_name in Optionals.Nome%type default '',
        t_tipologia in VARCHAR default null,
        t_referente_matr in Taxi.FK_Referente%type default null,
        t_targa in Taxi.Targa%type default null,
        t_cilindrata in Taxi.Cilindrata%type default null,
        t_nposti in Taxi.Nposti%type default null,
        t_km in Taxi.Km%type default null,
        t_tariffa in Taxi.Tariffa%type default null,
        t_IDoptionals in varchar2 default null
    )is
    BEGIN
        IF g2S.checkNomeOptionals(o_name) THEN
            insertOptional(id_ses=>id_ses, o_name=>o_name, o_IDtaxi=>o_IDtaxi, t_tipologia=>t_tipologia, t_referente_matr=>t_referente_matr, t_targa=>t_targa, t_cilindrata=>t_cilindrata, t_nposti=>t_nposti, t_km=>t_km, t_tariffa=>t_tariffa, t_IDoptionals=>t_IDoptionals);
        ELSE
            gui.REINDIRIZZA(link ||u_root||'.inserisciOptional?id_ses='||id_ses||
                                '' ||chr(38) || 'o_IDtaxi='||o_IDtaxi ||
                                '' ||chr(38) || 't_tipologia='||t_tipologia ||
                                '' ||chr(38) || 't_referente_matr='||t_referente_matr ||
                                '' ||chr(38) || 't_targa='||t_targa ||
                                '' ||chr(38) || 't_cilindrata='||t_cilindrata ||
                                '' ||chr(38) || 't_nposti='||t_nposti ||
                                '' ||chr(38) || 't_km='||t_km ||
                                '' ||chr(38) || 't_tariffa='||t_tariffa ||
                                '' ||chr(38) || 't_IDoptionals='||t_IDoptionals ||
                                '' ||chr(38)||'message=è già presente un optional con quel nome');
        END IF;
    END checkInserimentoOptional;

    PROCEDURE insertOptional(
        id_ses in SessioniDipendenti.IDSessione%type,
        o_IDtaxi in Taxi.IDtaxi%type default null,
        o_name in Optionals.Nome%type,
        t_tipologia in VARCHAR default null,
        t_referente_matr in Taxi.FK_Referente%type default null,
        t_targa in Taxi.Targa%type default null,
        t_cilindrata in Taxi.Cilindrata%type default null,
        t_nposti in Taxi.Nposti%type default null,
        t_km in Taxi.Km%type default null,
        t_tariffa in Taxi.Tariffa%type default null,
        t_IDoptionals in varchar2 default null
    )is
    begin
        savepoint sp1;
        BEGIN
            INSERT INTO OPTIONALS (Nome)
            VALUES (o_name);
            COMMIT;
            IF t_tipologia IS NULL THEN
                gui.REINDIRIZZA(link||u_root||'.visualizzaOptionals?id_ses='||id_ses||
                                                        '' ||chr(38) || 'o_IDtaxi='||o_IDtaxi||''||chr(38)|| 'posMessage=inserimento effettuato con successo');
            ELSE
                gui.REINDIRIZZA(link ||u_root||'.inserisciTaxi?id_ses='||id_ses||
                                    '' ||chr(38) || 't_tipologia='||t_tipologia ||
                                    '' ||chr(38) || 't_referente_matr='||t_referente_matr ||
                                    '' ||chr(38) || 't_targa='||t_targa ||
                                    '' ||chr(38) || 't_cilindrata='||t_cilindrata ||
                                    '' ||chr(38) || 't_nposti='||t_nposti ||
                                    '' ||chr(38) || 't_km='||t_km ||
                                    '' ||chr(38) || 't_tariffa='||t_tariffa ||
                                    '' ||chr(38) || 't_IDoptionals='||t_IDoptionals ||
                                    '' ||chr(38)||'posMessage=inserimento effettuato con successo');
            END IF;
            EXCEPTION
            WHEN OTHERS THEN
                -- Se c'è un errore, esegue il rollback alla savepoint e gestisce l'errore
                rollback to sp1;
                gui.REINDIRIZZA(link ||u_root||'.visualizzaOptional?id_ses='||id_ses||chr(38)||'negMessage=Inserimento%20non%20avvenuto%20a%20causa%20di%20un%20errore');
        END;
    end insertOptional;

----------------------  CORSE NON PRENOTATE   ----------------------
    procedure visualizzaCorseNonPrenotate(
        id_ses in SessioniDipendenti.IDSessione%type,
        c_Data_min in varChar2 default null,
        c_Data_max in varChar2 default null,
        c_Ora_min in varChar2 default null,
        c_Ora_max in varChar2 default null,
        c_Durata_min in CorseNonPrenotate.Durata%type default null,
        c_Durata_max in CorseNonPrenotate.Durata%type default null,
        c_Importo_min in CorseNonPrenotate.Importo%type default null,
        c_Importo_max in CorseNonPrenotate.Importo%type default null,
        c_Passeggeri_min in CorseNonPrenotate.Passeggeri%type default null,
        c_Passeggeri_max in CorseNonPrenotate.Passeggeri%type default null,
        c_Km_min in CorseNonPrenotate.Km%type default null,
        c_Km_max in CorseNonPrenotate.Km%type default null,
        c_Partenza in CorseNonPrenotate.Partenza%type default null,
        c_Arrivo in CorseNonPrenotate.Arrivo%type default null,
        c_Targa in Taxi.Targa%type default null,
        c_Matricola in Dipendenti.Matricola%type default null,
        negMessage in varchar default null,
        posMessage in varchar default null
    )IS
    b BOOLEAN;
    numCorse int;
    head gui.STRINGARRAY;
    begin
        IF SessionHandler.getRuolo(id_ses) = 'Operatore' or SessionHandler.getRuolo(id_ses) = 'Cliente'THEN
            gui.ApriPagina('visualizzaCorseNonPrenotate', id_ses);
            gui.AGGIUNGIPOPUP(false,'Non hai il permesso per accedere a questa pagina', costanti.url||'gui.homePage?idSessione='||id_ses);
            return;
        end if;

        htp.prn('<script>   const newUrl = "'||u_root||'.visualizzaCorseNonPrenotate?id_ses='||id_ses||
                chr(38)||'c_Data_min='||c_Data_min||
                chr(38)||'c_Data_max='||c_Data_max||
                chr(38)||'c_Ora_min='||c_Ora_min||
                chr(38)||'c_Ora_max='||c_Ora_max||
                chr(38)||'c_Durata_min='||c_Durata_min||
                chr(38)||'c_Durata_max='||c_Durata_max||
                chr(38)||'c_Importo_min='||c_Importo_min||
                chr(38)||'c_Importo_max='||c_Importo_max||
                chr(38)||'c_Passeggeri_min='||c_Passeggeri_min||
                chr(38)||'c_Passeggeri_max='||c_Passeggeri_max||
                chr(38)||'c_Km_min='||c_Km_min||
                chr(38)||'c_Km_max='||c_Km_max||
                chr(38)||'c_Partenza='||c_Partenza||
                chr(38)||'c_Arrivo='||c_Arrivo||
                chr(38)||'c_Targa='||c_Targa||
                chr(38)||'c_Matricola='||c_Matricola||'";
                history.replaceState(null, null, newUrl);</script>');
        g2S.initialization(id_ses,'visualizzaCorseNonPrenotate','Visualizza Corse Non Prenotate');

        IF (SessionHandler.getRuolo(id_ses) = 'Autista') THEN

            numCorse:=g2s.countCorse(SessionHandler.getIDuser(id_ses));
            gui.aggiungiIntestazione('Hai effettuato un numero di corse non prenotate pari a: ' || numCorse,'h3');

            IF (g2s.isInTurno(c_autista=>SessionHandler.getIDuser(id_ses))) THEN
                IF ( g2s.hasNoCorseAttive(c_autista=>SessionHandler.getIDuser(id_ses))) THEN
                gui.acapo();
                gui.BOTTONEAGGIUNGI(testo => 'Aggiungi corse non prenotate', url => u_root || '.inserisciCorseNonPrenotate?id_ses='||id_ses);
                gui.ACAPO();
                ELSE
                gui.aggiungiIntestazione('Termina le corse prima di inserirne una nuova','h3');
                END IF;
            END IF;
        END IF;

        IF SessionHandler.getRuolo(id_ses) = 'Manager' OR SessionHandler.getRuolo(id_ses) = 'Contabile' THEN
            head := gui.StringArray('Data e Ora', 'Durata', 'Importo', 'Numero Passeggeri', 'Km', 'Partenza', 'Arrivo', 'Taxi Utilizzato', 'Autista');
            gui.BOTTONEAGGIUNGI(testo=>'Visualizza Numero Corse NP di ogni autista', url=>u_root || '.visualizzaCorseNPAutista?id_ses='||id_ses);
            gui.aCapo();
        ELSE
            head := gui.StringArray('Data e Ora', 'Durata', 'Importo', 'Numero Passeggeri', 'Km', 'Partenza', 'Arrivo', 'Taxi Utilizzato', ' ');
        end if;

        IF posMessage IS NOT NULL THEN
            gui.AggiungiPopup(successo => true, testo => posMessage);
            gui.ACAPO();
        ELSE
            IF negMessage IS NOT NULL THEN
                gui.AggiungiPopup(successo => false, testo => negMessage);
                gui.ACAPO();
            end if;
        end if;
        -- FORM
        gui.ApriFormFiltro(u_root || '.visualizzaCorseNonPrenotate');

        gui.AggiungiCampoFormFiltro(tipo => 'date', nome => 'c_Data_min', value => c_Data_min, placeholder => 'Data minima');
        gui.AggiungiCampoFormFiltro(tipo => 'date', nome => 'c_Data_max', value => c_Data_max, placeholder => 'Data massima');
        gui.AggiungiCampoFormFiltro(tipo => 'time', nome => 'c_Ora_min', value => c_Ora_min, placeholder => 'Ora minima');
        gui.AggiungiCampoFormFiltro(tipo => 'time', nome => 'c_Ora_max', value => c_Ora_max, placeholder => 'Ora massima');
        gui.AggiungiCampoFormFiltro(tipo => 'number', nome => 'c_Durata_min', value => c_Durata_min, placeholder => 'Durata minima');
        gui.AggiungiCampoFormFiltro(tipo => 'number', nome => 'c_Durata_max', value => c_Durata_max, placeholder => 'Durata massima');

        gui.AggiungiRigaTabella();
        gui.AggiungiCampoFormFiltro(tipo => 'number', nome => 'c_Importo_min', value => c_Importo_min, placeholder => 'Importo minimo');
        gui.AggiungiCampoFormFiltro(tipo => 'number', nome => 'c_Importo_max', value => c_Importo_max, placeholder => 'Importo massimo');
        gui.AggiungiCampoFormFiltro(tipo => 'number', nome => 'c_Passeggeri_min', value => c_Passeggeri_min, placeholder => 'N. Passeggeri minimi');
        gui.AggiungiCampoFormFiltro(tipo => 'number', nome => 'c_Passeggeri_max', value => c_Passeggeri_max, placeholder => 'N. Passeggeri massimi');
        gui.AggiungiCampoFormFiltro(tipo => 'number', nome => 'c_Km_min', value => c_Km_min, placeholder => 'Km minimi');
        gui.AggiungiCampoFormFiltro(tipo => 'number', nome => 'c_Km_max', value => c_Km_max, placeholder => 'Km massimi');

        gui.AggiungiRigaTabella();
        gui.AggiungiCampoFormFiltro(tipo => 'text', nome => 'c_Partenza', value => c_Partenza, placeholder => 'Partenza');
        gui.AggiungiCampoFormFiltro(tipo => 'text', nome => 'c_Arrivo', value => c_Arrivo, placeholder => 'Arrivo');
        gui.ApriSelectFormFiltro('c_Targa', 'Targa');
        for x in (
            SELECT Targa
            FROM Taxi
            ORDER BY Targa
        )
        loop
            IF c_Targa = x.Targa THEN b := true; ELSE b := false; END IF;
            gui.AggiungiOpzioneSelect(x.Targa, b, x.Targa);
        END LOOP;
        gui.ChiudiSelectFormFiltro;
        IF SessionHandler.getRuolo(id_ses) = 'Manager' OR SessionHandler.getRuolo(id_ses) = 'Contabile' THEN
            -- MATRICOLA
            gui.ApriSelectFormFiltro('c_Matricola', 'Autista');
            IF c_Matricola IS NULL THEN b := true; ELSE b := false; END IF;
            gui.AggiungiOpzioneSelect(null, b, '-');
            for x in (
                SELECT Matricola, Nome, Cognome
                FROM Dipendenti d
                Order By Matricola
            )
            loop
                IF c_Matricola = x.Matricola THEN b := true; ELSE b := false; END IF;
                gui.AggiungiOpzioneSelect(x.Matricola, b, x.Matricola||' - '||x.Nome||' '||x.Cognome);
            END LOOP;
            gui.ChiudiSelectFormFiltro;
        end if;
        gui.AggiungiCampoFormHidden(tipo => 'number', nome => 'id_ses', value => id_ses);
        gui.AggiungiCampoFormFiltro(tipo => 'submit', nome => '', placeholder => 'Filtra');
        gui.chiudiFormFiltro();

        gui.ACAPO();

        g2S.resetFilter(url => '.visualizzaCorseNonPrenotate', id_ses => id_ses);

        gui.ApriTabella(head);


        for x in (
            SELECT cnp.IDcorsa, cnp.FK_Standard, cnp.DataOra, cnp.Durata, cnp.Importo, cnp.Passeggeri, cnp.Km, cnp.Partenza, cnp.Arrivo, t.Targa, t.IDtaxi, d.Nome, d.Cognome, d.Matricola
            FROM CorseNonPrenotate cnp, TaxiStandard ts, Taxi t, Turni tu, Autisti a, Dipendenti d
            WHERE cnp.FK_Standard = ts.FK_Taxi AND
                ts.FK_Taxi = t.IDtaxi AND
                t.IDtaxi = tu.FK_Taxi AND
                cnp.DataOra >= tu.DataOraInizio AND
                cnp.DataOra <= tu.DataOraFine AND
                tu.FK_Autista = a.FK_Dipendente AND
                a.FK_Dipendente = d.Matricola AND
                (
                    (-- AUTISTA
                        (SessionHandler.getRuolo(id_ses) = 'Autista') AND
                        (
                            (
                                d.Matricola = SessionHandler.getIDuser(id_ses)
                            )OR(
                                t.FK_Referente = SessionHandler.getIDuser(id_ses)
                            )
                        )
                    ) OR (
                        (
                            ( -- MANAGER
                                SessionHandler.getRuolo(id_ses) = 'Manager'
                            ) OR ( -- CONTABILE
                                SessionHandler.getRuolo(id_ses) = 'Contabile'
                            )
                        ) AND (
                            (c_Matricola = d.Matricola or c_Matricola is null)
                        )
                    )
                ) AND

                -- data
                ((to_date(c_Data_min, 'YYYY-MM-DD') <= trunc(cnp.DataOra)) or c_Data_min is null) AND
                ((to_date(c_Data_max, 'YYYY-MM-DD') >= trunc(cnp.DataOra)) or c_Data_max is null) AND
                -- ora
                (c_Ora_min <= to_char(cnp.DataOra, 'HH24:SS:MI') or c_Ora_min is null) AND
                (c_Ora_max >= to_char(cnp.DataOra, 'HH24:SS:MI') or c_Ora_max is null) AND
                -- durata
                (c_Durata_min <= cnp.Durata or c_Durata_min is null) AND
                (c_Durata_max >= cnp.Durata or c_Durata_max is null) AND
                -- importo
                (c_Importo_min <= cnp.Importo or c_Importo_min is null) AND
                (c_Importo_max >= cnp.Importo or c_Importo_max is null) AND
                -- passeggeri
                (c_Passeggeri_min <= cnp.Passeggeri or c_Passeggeri_min is null) AND
                (c_Passeggeri_max >= cnp.Passeggeri or c_Passeggeri_max is null) AND
                -- km
                (c_Km_min <= cnp.Km or c_Km_min is null) AND
                (c_Km_max >= cnp.Km or c_Km_max is null) AND
                -- partenza
                (LOWER(replace(cnp.Partenza, ' ', '')) LIKE '%'||(LOWER(replace(c_Partenza, ' ', '')))||'%' or c_Partenza is null) AND
                -- arrivo
                (LOWER(replace(cnp.Arrivo, ' ', '')) LIKE '%'||(LOWER(replace(c_Arrivo, ' ', '')))||'%' or c_Arrivo is null) AND
                -- targa
                (LOWER(replace(t.Targa, ' ', '')) LIKE '%'||(LOWER(replace(c_Targa, ' ', '')))||'%' or c_Targa is null)
        )
        loop

            -- Esegui le operazioni sui dati recuperati
            gui.AggiungiRigaTabella();
            gui.AggiungiElementoTabella(TO_CHAR(x.DataOra, 'DD-MM-YYYY HH24:MI:SS'));
            gui.AggiungiElementoTabella(COALESCE(x.Durata, '') || ' min');
            gui.AggiungiElementoTabella(COALESCE(x.Importo, '0') || ' €');
            gui.AggiungiElementoTabella(x.Passeggeri  || '');
            gui.AggiungiElementoTabella(COALESCE(x.Km, '0') || ' km');
            gui.AggiungiElementoTabella(x.Partenza  || '');
            gui.AggiungiElementoTabella(COALESCE(x.Arrivo, '-'));
            gui.apriElementoPulsanti;
            gui.AggiungiPulsanteGenerale(testo => x.Targa  || '',collegamento => ''''||u_root || '.visualizzaUnTaxi?id_ses=' || id_ses || '' || chr(38) || 't_IDtaxi=' || x.IDtaxi||'''');
            gui.chiudiElementoPulsanti;
            IF SessionHandler.getRuolo(id_ses) = 'Manager' OR SessionHandler.getRuolo(id_ses) = 'Contabile' THEN
                gui.apriElementoPulsanti;
                gui.AggiungiPulsanteGenerale(testo => x.Matricola|| ' - ' ||x.Nome  || ' ' || x.Cognome,
                                             collegamento => ''''||link || '' ||u_user||'.gruppo4.visualizzaDipendente?idSessione=' || id_ses
                                                                || chr(38) || 'IMatricola='||x.Matricola||'''');
                gui.chiudiElementoPulsanti;
            end if;
            IF g2S.canModify_CNP(id_ses, x.IDcorsa) THEN
                gui.APRIELEMENTOPULSANTI();
                IF isDaCompletare(x.IDCORSA) THEN
                    gui.AggiungiPulsanteGenerale(testo => 'Completa la corsa',collegamento =>  ''''||u_root || '.completaCorseNonPrenotate?id_ses=' || id_ses || '' || chr(38) || 'c_id=' || x.IDcorsa||'''');
                ELSE
                    gui.AggiungiPulsanteModifica(gruppo2.u_root || '.modificaCorseNonPrenotate?id_ses='||id_ses||''||chr(38)||'c_id='||x.IDcorsa||'');
                end if;
                gui.chiudiElementoPulsanti;
            END IF;
            gui.ChiudiRigaTabella();
        END LOOP;

        gui.ChiudiTabella();
        gui.ACAPO();
        gui.CHIUDIPAGINA();

    end visualizzaCorseNonPrenotate;

    PROCEDURE inserisciCorseNonPrenotate(
        id_ses in SessioniDipendenti.IDSessione%type,
        c_passeggeri in CorseNonPrenotate.Passeggeri%type default null,
        c_partenza in CorseNonPrenotate.Partenza%type default null,
        c_message in VARCHAR default ''
    )
    IS
    BEGIN
        g2S.initialization(id_ses,'inserisciCorseNonPrenotate','Inserisci una corsa non prenotata');

        IF c_message IS NOT NULL THEN
            gui.AggiungiPopup(false,c_message);
            gui.aCapo();
        END IF;

        gui.acapo();
        gui.aCapo();
        gui.BOTTONEAGGIUNGI(testo => 'Back to Visualizza Corse Non Prenotate', url => u_root || '.visualizzaCorseNonPrenotate?id_ses='||id_ses);
        gui.ACAPO();

        gui.AggiungiForm(name=>'Inserisci Corsa Non Prenotata', url=> u_root || '.checkInserimentoCNP');

        gui.aCapo();
        gui.AggiungiLabel('c_passeggeri','Numero Passeggeri:');
        gui.AggiungiInput(tipo => 'number', nome => 'c_passeggeri', value => c_passeggeri, placeholder => 'Numero passeggeri', required => true);

        gui.aCapo();
        gui.aCapo();
        gui.AggiungiLabel('c_partenza','Via di partenza:');
        gui.AggiungiInput(tipo => 'text', nome => 'c_partenza', value => c_partenza, placeholder => 'Via di Partenza', required => true);


        gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 'id_ses', value => id_ses);
        gui.aCapo();

        gui.aggiungiBottoneSubmit(value => 'Inserisci Corsa');
        gui.chiudiForm();

        gui.CHIUDIPAGINA();

    END inserisciCorseNonPrenotate;

    PROCEDURE checkInserimentoCNP(
        id_ses in SessioniDipendenti.IDSessione%type,
        c_passeggeri in CorseNonPrenotate.Passeggeri%type,
        c_partenza in CorseNonPrenotate.Partenza%type
    )
    IS
    BEGIN
       IF g2s.checkNumPasseggeri(c_passeggeri,SessionHandler.getIDuser(id_ses)) THEN
       insertCorseNonPrenotate(id_ses=>id_ses, c_passeggeri=>c_passeggeri, c_partenza=>c_partenza, c_autista=>SessionHandler.getIDuser(id_ses));
       ELSE
        gui.REINDIRIZZA(link||u_user||'.gruppo2.inserisciCorseNonPrenotate?id_ses='||id_ses||
                                                    '' ||chr(38) || 'c_passeggeri='|| c_passeggeri ||
                                                    '' ||chr(38) || 'c_partenza='|| c_partenza ||
                                                    '' ||chr(38) || 'c_message=Numero di passeggeri non valido');
        END IF;
    END checkInserimentoCNP;

    PROCEDURE insertCorseNonPrenotate(
        id_ses in SessioniDipendenti.IDSessione%type,
        c_passeggeri in CorseNonPrenotate.Passeggeri%type,
        c_partenza in CorseNonPrenotate.Partenza%type,
        c_autista in Autisti.FK_Dipendente%type
    )is
    begin
    savepoint sp1;
        BEGIN
        INSERT INTO CORSENONPRENOTATE (DataOra, Durata, Importo, Passeggeri, KM, Partenza, Arrivo, FK_Standard)
        VALUES (SYSDATE, null, null, c_passeggeri, null, c_partenza, null, g2s.getTaxiId(c_autista));
        COMMIT;
        gui.REINDIRIZZA(link||u_user||'.gruppo2.visualizzaCorseNonPrenotate?id_ses='||id_ses||
                                                    '' ||chr(38) || 'posMessage=inserimento corsa effettuato con successo');

        EXCEPTION
            WHEN OTHERS THEN
                -- Se c'è un errore, esegue il rollback alla savepoint e gestisce l'errore
                rollback to sp1;
                gui.REINDIRIZZA(link ||u_root||'.inserisciCorseNonPrenotate?id_ses='||id_ses||
                                '' ||chr(38) || 'c_passeggeri='|| c_passeggeri ||
                                '' ||chr(38) || 'c_partenza='|| c_partenza ||
                                '' ||chr(38) || 'c_message=Inserimento non avvenuto a causa di un errore');
        END;
    end insertCorseNonPrenotate;

    FUNCTION isDaCompletare(
        c_id in CorseNonPrenotate.IDcorsa%type
    ) RETURN BOOLEAN IS
    c_durata CorseNonPrenotate.IDcorsa%type;
    c_KM CorseNonPrenotate.KM%type;
    c_importo CorseNonPrenotate.importo%type;
    c_arrivo CorseNonPrenotate.arrivo%type;
    begin
        SELECT c.Durata, c.Importo, c.KM, c.Arrivo INTO c_durata, c_importo, c_KM, c_arrivo
        FROM CORSENONPRENOTATE c
        WHERE c.IDcorsa=c_id;

        IF c_durata IS NULL AND c_importo IS NULL AND c_KM IS NULL AND c_arrivo IS NULL THEN
        RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;

    end isDaCompletare;

    PROCEDURE completaCorseNonPrenotate(
        id_ses in SessioniDipendenti.IDSessione%type,
        c_id in CorseNonPrenotate.IDcorsa%type,
        kmpercorsi in CorseNonPrenotate.Km%type default null,
        luogoarrivo in CorseNonPrenotate.Arrivo%type default null,
        message in VARCHAR default null
    )
    is
    begin
        IF SessionHandler.getRuolo(id_ses) != 'Autista' THEN
            gui.ApriPagina('visualizzaCorseNonPrenotate', id_ses);
            gui.AGGIUNGIPOPUP(false,'Non hai il permesso per accedere a questa pagina', costanti.url||'gui.homePage?idSessione='||id_ses);
            return;
        end if;
        IF isDaCompletare(c_id) THEN

            g2S.initialization(id_ses,'completaCorsaNonPrenotata','Corsa non prenotata numero ' || c_id ||': completa i dati');

            IF message IS NOT NULL THEN
                gui.AggiungiPopup(false,message);
                gui.aCapo();
            END IF;

            gui.acapo();
            gui.aCapo();
            gui.BOTTONEAGGIUNGI(testo => 'Back to Visualizza Corse Non Prenotate', url => u_root || '.visualizzaCorseNonPrenotate?id_ses='||id_ses);
            gui.ACAPO();

            gui.aggiungiForm(name => 'Completa corsa non prenotata', url => u_root||'.checkCompletaCNP');
            gui.aCapo();
            gui.AggiungiLabel('c_id','Corsa:');
            gui.aCapo();
            gui.aCapo();
            gui.aggiungilabel('c_kmpercorsi', 'Kilometri percorsi:');
            gui.AggiungiInput(tipo => 'number', nome => 'c_kmpercorsi', value => kmpercorsi, placeholder => 'Kilometri percorsi ', required => true);
            gui.aggiungilabel('c_luogoarrivo', 'Luogo di arrivo:');
            gui.AggiungiInput(tipo => 'text', nome => 'c_luogoarrivo', value => luogoarrivo, placeholder => 'Via di arrivo ', required => true);

            gui.aCapo();
            gui.aCapo();

            gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 'id_ses', value => id_ses);
            gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 'c_id', value => c_id);

            gui.aggiungiBottoneSubmit(value => 'Inserisci Dati');
            gui.chiudiForm();

            gui.aggiungiForm(name => 'visualizzaCorseNonPrenotate', url => u_root||'.visualizzaCorseNonPrenotate');
            gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 'id_ses', value => id_ses);
            gui.chiudiForm();
        ELSE gui.REINDIRIZZA(link||u_user||'.gruppo2.visualizzaCorseNonPrenotate?id_ses='||id_ses||
                                                    '' ||chr(38) || 'negMessage=La corsa ha già tutti i dati modificala');
        END IF;

    end completaCorseNonPrenotate;

    PROCEDURE checkCompletaCNP(
        id_ses in SessioniDipendenti.IDSessione%type,
        c_id in CorseNonPrenotate.IDCorsa%type,
        c_kmpercorsi in CorseNonPrenotate.KM%type default null,
        c_luogoarrivo in CorseNonPrenotate.Arrivo%type default null,
        message in VARCHAR default null
    )is
    begin
        IF c_kmpercorsi>0 THEN
            gui.REINDIRIZZA(link||u_user||'.gruppo2.updateCNPCompletamento?id_ses='||id_ses||
                                                    ''||chr(38)||'c_id='||c_id||
                                                    '' ||chr(38) || 'c_luogoarrivo='||c_luogoarrivo ||
                                                    '' ||chr(38) || 'c_kmpercorsi='||c_kmpercorsi);
        ELSE
            gui.REINDIRIZZA(link||u_user||'.gruppo2.completaCorseNonPrenotate?id_ses='||id_ses||''||chr(38)||'c_id='||c_id||
                                                    '' ||chr(38) || 'luogoarrivo='||c_luogoarrivo || '' ||chr(38) || 'message=Il kilometraggio deve essere maggiore di 0');
        END IF;

    end checkCompletaCNP;

    PROCEDURE updateCNPCompletamento(
        id_ses in SessioniDipendenti.IDSessione%type,
        c_id in CorseNonPrenotate.IDCorsa%type,
        c_kmpercorsi in CorseNonPrenotate.KM%type default null,
        c_luogoarrivo in CorseNonPrenotate.Arrivo%type default null,
        message in VARCHAR default null
    )is
    tariffa Taxi.Tariffa%type;
    dataOraCorsa DATE;
    durataCorsa NUMBER;
    begin
        savepoint sp1;
        BEGIN
            SELECT t.tariffa INTO tariffa
            FROM TAXI t
            WHERE t.IDtaxi=(SELECT c.FK_Standard FROM CORSENONPRENOTATE c WHERE c.IDcorsa=c_id);

            SELECT c.DataOra INTO dataOraCorsa FROM CORSENONPRENOTATE c WHERE c.IDcorsa=c_id;

            durataCorsa:=(SYSDATE - dataOraCorsa) * 1440;
            UPDATE CORSENONPRENOTATE c
            SET c.Durata= durataCorsa,
                c.Importo=tariffa*durataCorsa,
                c.KM = c_kmpercorsi,
                c.Arrivo=c_luogoarrivo
            WHERE c.IDCorsa = c_id;

            COMMIT;

            gui.REINDIRIZZA(link||u_user||'.gruppo2.visualizzaCorseNonPrenotate?id_ses='||id_ses||
                                                        '' ||chr(38) || 'posMessage=dati inseriti con successo');
            EXCEPTION
            WHEN OTHERS THEN
                -- Se c'è un errore, esegue il rollback alla savepoint e gestisce l'errore
                rollback to sp1;
                gui.REINDIRIZZA(link ||u_root||'.visualizzaCorseNonPrenotate?id_ses='||id_ses||chr(38)||'negMessage=Completamento%20non%20avvenuto%20a%20causa%20di%20un%20errore');
        END;
    end updateCNPCompletamento;

    PROCEDURE modificaCorseNonPrenotate(
        id_ses in SessioniDipendenti.IDSessione%type,
        c_id in CorseNonPrenotate.IDcorsa%type,
        c_kmpercorsi in CorseNonPrenotate.Km%type default null,
        c_luogoarrivo in CorseNonPrenotate.Arrivo%type default null,
        c_passeggeri in CorseNonPrenotate.Passeggeri%type default null,
        c_luogopartenza in CorseNonPrenotate.Partenza%type default null,
        message in VARCHAR default null
    )
    is
    oldKm CorseNonPrenotate.Km%type default null;
    oldPartenza CorseNonPrenotate.Partenza%type default null;
    oldArrivo CorseNonPrenotate.Arrivo%type default null;
    oldPasseggeri CorseNonPrenotate.Passeggeri%type default null;
    begin
        IF SessionHandler.getRuolo(id_ses) != 'Autista' THEN
            gui.ApriPagina('visualizzaCorseNonPrenotate', id_ses);
            gui.AGGIUNGIPOPUP(false,'Non hai il permesso per accedere a questa pagina', costanti.url||'gui.homePage?idSessione='||id_ses);
            return;
        end if;

        g2S.initialization(id_ses,'modificaCorsaNonPrenotata','Corsa non prenotata numero ' || c_id ||': modifica i dati');

        IF message IS NOT NULL THEN
            gui.AggiungiPopup(false,message);
            gui.aCapo();
        END IF;

        SELECT c.KM INTO oldKm FROM CORSENONPRENOTATE c WHERE c.IDcorsa=c_id;
        SELECT c.Partenza INTO oldPartenza FROM CORSENONPRENOTATE c WHERE c.IDcorsa=c_id;
        SELECT c.Arrivo INTO oldArrivo FROM CORSENONPRENOTATE c WHERE c.IDcorsa=c_id;
        SELECT c.Passeggeri INTO oldPasseggeri FROM CORSENONPRENOTATE c WHERE c.IDcorsa=c_id;

        gui.acapo();
        gui.aCapo();
        gui.BOTTONEAGGIUNGI(testo => 'Back to Visualizza Corse Non Prenotate', url => u_root || '.visualizzaCorseNonPrenotate?id_ses='||id_ses);
        gui.ACAPO();

        gui.aggiungiForm(name => 'Modifica corsa non prenotata', url => u_root||'.checkModificaCNP');
        gui.aCapo();
        gui.AggiungiLabel('c_id','Corsa:');
        gui.aCapo();
        gui.aCapo();
        gui.aggiungilabel('c_kmpercorsi', 'Kilometri percorsi:');
        gui.AggiungiInput(tipo => 'number', nome => 'c_kmpercorsi', value => oldKm, placeholder => 'Kilometri percorsi '|| c_kmpercorsi, required => true);
        gui.aggiungilabel('c_luogopartenza', 'Luogo di partenza:');
        gui.AggiungiInput(tipo => 'text', nome => 'c_luogopartenza', value => oldPartenza, placeholder => 'Via di partenza '|| c_luogopartenza, required => true);
        gui.aggiungilabel('c_luogoarrivo', 'Luogo di arrivo:');
        gui.AggiungiInput(tipo => 'text', nome => 'c_luogoarrivo', value => oldArrivo, placeholder => 'Via di arrivo '|| c_luogoarrivo, required => true);
        gui.aggiungilabel('c_passeggeri', 'Numero passeggeri:');
        gui.AggiungiInput(tipo => 'number', nome => 'c_passeggeri', value => oldPasseggeri, placeholder => 'Numero di passeggeri '|| c_passeggeri, required => true);


        gui.aCapo();
        gui.aCapo();

        gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 'id_ses', value => id_ses);
        gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 'c_id', value => c_id);

        gui.aggiungiBottoneSubmit(value => 'Inserisci Dati');
        gui.chiudiForm();

        gui.aggiungiForm(name => 'visualizzaCorseNonPrenotate', url => u_root||'.visualizzaCorseNonPrenotate');
        gui.AggiungiCampoFormFiltro(tipo => 'hidden', nome => 'id_ses', value => id_ses);
        gui.chiudiForm();

    end modificaCorseNonPrenotate;

    PROCEDURE checkModificaCNP(
        id_ses in SessioniDipendenti.IDSessione%type,
        c_id in CorseNonPrenotate.IDCorsa%type,
        c_kmpercorsi in CorseNonPrenotate.KM%type default null,
        c_luogoarrivo in CorseNonPrenotate.Arrivo%type default null,
        c_passeggeri in CorseNonPrenotate.Passeggeri%type default null,
        c_luogopartenza in CorseNonPrenotate.Partenza%type default null,
        message in VARCHAR default null
    )is
    nPasseggeriTaxi Taxi.Nposti%type;
    begin
        SELECT t.Nposti INTO nPasseggeriTaxi
        FROM Taxi t, CorseNonPrenotate c
        WHERE c.IDcorsa=c_id AND
              c.FK_STANDARD = t.IDTAXI;

        IF ( nPasseggeriTaxi<c_passeggeri OR c_passeggeri<=0) THEN
            gui.REINDIRIZZA(link||u_user||'.gruppo2.modificaCorseNonPrenotate?id_ses='||id_ses||
                                                    '' ||chr(38) || 'c_id='|| c_id ||
                                                    '' ||chr(38) || 'c_passeggeri='|| c_passeggeri ||
                                                    '' ||chr(38) || 'c_luogopartenza='|| c_luogopartenza ||
                                                    '' ||chr(38) || 'c_luogoarrivo='|| c_luogoarrivo ||
                                                    '' ||chr(38) || 'message=Il numero di passeggeri deve essere minore o uguale del numero di posti del taxi e maggiore di 0');
        ELSE
            IF c_kmpercorsi>0 THEN
                gui.REINDIRIZZA(link||u_user||'.gruppo2.updateCNP?id_ses='||id_ses||
                                                    ''||chr(38)||'c_id='||c_id||
                                                    '' ||chr(38) || 'c_luogoarrivo='||c_luogoarrivo ||
                                                    '' ||chr(38) || 'c_kmpercorsi='||c_kmpercorsi ||
                                                    '' ||chr(38) || 'c_luogopartenza='||c_luogopartenza ||
                                                    '' ||chr(38) || 'c_passeggeri='||c_passeggeri
                                                    );
            ELSE
                gui.REINDIRIZZA(link||u_user||'.gruppo2.modificaCorseNonPrenotate?id_ses='||id_ses||
                                                    '' ||chr(38) || 'c_id='|| c_id ||
                                                    '' ||chr(38) || 'c_passeggeri='|| c_passeggeri ||
                                                    '' ||chr(38) || 'c_luogopartenza='|| c_luogopartenza ||
                                                    '' ||chr(38) || 'c_luogoarrivo='|| c_luogoarrivo ||
                                                    '' ||chr(38) || 'message=Kilometraggio non valido');
            END IF;
        END IF;

    end checkModificaCNP;

    PROCEDURE updateCNP(
        id_ses in SessioniDipendenti.IDSessione%type,
        c_id in CorseNonPrenotate.IDCorsa%type,
        c_kmpercorsi in CorseNonPrenotate.KM%type default null,
        c_luogoarrivo in CorseNonPrenotate.Arrivo%type default null,
        c_passeggeri in CorseNonPrenotate.Passeggeri%type default null,
        c_luogopartenza in CorseNonPrenotate.Partenza%type default null,
        message in VARCHAR default null
    )is
    begin
        savepoint sp1;
        BEGIN
            UPDATE CORSENONPRENOTATE c
            SET c.KM = c_kmpercorsi,
                c.Arrivo=c_luogoarrivo,
                c.Passeggeri=c_passeggeri,
                c.Partenza=c_luogopartenza
            WHERE c.IDCorsa = c_id;

            COMMIT;

            gui.REINDIRIZZA(link||u_user||'.gruppo2.visualizzaCorseNonPrenotate?id_ses='||id_ses||
                                                        '' ||chr(38) || 'posMessage=dati inseriti con successo');
            EXCEPTION
            WHEN OTHERS THEN
                -- Se c'è un errore, esegue il rollback alla savepoint e gestisce l'errore
                rollback to sp1;
                gui.REINDIRIZZA(link ||u_root||'.visualizzaCorseNonPrenotate?id_ses='||id_ses||chr(38)||'negMessage=Modifica%20non%20avvenuta%20a%20causa%20di%20un%20errore');
        END;
    end updateCNP;

--------------------STATISTICHE--------------------
    PROCEDURE visualizzaCorseNPAutista(
        id_ses in SessioniDipendenti.IDSessione%type,
        a_Matricola in Dipendenti.Matricola%type default null,
        a_Nome in Dipendenti.Nome%type default null,
        a_Cognome in Dipendenti.Cognome%type default null,
        a_NumCorseMin in Number default null,
        a_NumCorseMax in Number default null,
        a_Data_min in varChar2 default null,
        a_Data_max in varChar2 default null,
        a_Ora_min in varChar2 default null,
        a_Ora_max in varChar2 default null,
        a_Durata_min in CorseNonPrenotate.Durata%type default null,
        a_Durata_max in CorseNonPrenotate.Durata%type default null,
        a_Importo_min in CorseNonPrenotate.Importo%type default null,
        a_Importo_max in CorseNonPrenotate.Importo%type default null
    )is
    v_query_sql VARCHAR2(1000);
    head gui.StringArray;
    begin

        g2S.initialization(id_ses,'visualizzaCorseNonPrenAutista','Visualizzazione Corse Non prenotate per autista');

        gui.BOTTONEAGGIUNGI(testo=>'Back to visualizza Corse NP', url=>u_root || '.visualizzaCorseNonPrenotate?id_ses='||id_ses);
        gui.acapo();
        gui.acapo();
        gui.acapo();
        gui.BOTTONEAGGIUNGI(testo=>'Visualizza i migliori autisti, secondo i filtri', url=>u_root || '.visualizzaBestCNPAutista?id_ses='||id_ses||
                                                                                        '' ||chr(38) || 'a_Matricola=' || a_Matricola ||
                                                                                        '' ||chr(38) || 'a_Nome=' || a_Nome ||
                                                                                        '' ||chr(38) || 'a_Cognome=' || a_Cognome ||
                                                                                        '' ||chr(38) || 'a_NumCorseMin=' || a_NumCorseMin ||
                                                                                        '' ||chr(38) || 'a_NumCorseMax=' || a_NumCorseMax ||
                                                                                        '' ||chr(38) || 'a_Data_min=' || a_Data_min ||
                                                                                        '' ||chr(38) || 'a_Data_max=' || a_Data_max ||
                                                                                        '' ||chr(38) || 'a_Ora_min=' || a_Ora_min ||
                                                                                        '' ||chr(38) || 'a_Ora_max=' || a_Ora_max ||
                                                                                        '' ||chr(38) || 'a_Durata_min=' || a_Durata_min ||
                                                                                        '' ||chr(38) || 'a_Durata_max=' || a_Durata_max ||
                                                                                        '' ||chr(38) || 'a_Importo_min=' || a_Importo_min ||
                                                                                        '' ||chr(38) || 'a_Importo_max=' || a_Importo_max
                                                                                        );
        -- FORM
        gui.ApriFormFiltro(u_root || '.visualizzaCorseNPAutista');
        gui.aCapo();

        gui.AggiungiCampoFormFiltro(tipo => 'date', nome => 'a_Data_min', value => a_Data_min, placeholder => 'Data minima');
        gui.AggiungiCampoFormFiltro(tipo => 'date', nome => 'a_Data_max', value => a_Data_max, placeholder => 'Data massima');
        gui.AggiungiCampoFormFiltro(tipo => 'time', nome => 'a_Ora_min', value => a_Ora_min, placeholder => 'Ora minima');
        gui.AggiungiCampoFormFiltro(tipo => 'time', nome => 'a_Ora_max', value => a_Ora_max, placeholder => 'Ora massima');
        gui.AggiungiRigaTabella();
        gui.AggiungiCampoFormFiltro(tipo => 'number', nome => 'a_Importo_min', value => a_Importo_min, placeholder => 'Minimo Importo');
        gui.AggiungiCampoFormFiltro(tipo => 'number', nome => 'a_Importo_max', value => a_Importo_max, placeholder => 'Massimo Importo');
        gui.AggiungiCampoFormFiltro(tipo => 'number', nome => 'a_numCorseMin', value => a_numCorseMin, placeholder => 'Minimo Numero Corse');
        gui.AggiungiCampoFormFiltro(tipo => 'number', nome => 'a_numCorseMax', value => a_numCorseMax, placeholder => 'Massimo Numero Corse');
        gui.AggiungiRigaTabella();
        gui.AggiungiCampoFormFiltro(tipo => 'number', nome => 'a_Matricola', value => a_Matricola, placeholder => 'Matricola');
        gui.AggiungiCampoFormFiltro(tipo => 'text', nome => 'a_Nome', value => a_Nome, placeholder => 'Nome');
        gui.AggiungiCampoFormFiltro(tipo => 'text', nome => 'a_Cognome', value => a_Cognome, placeholder => 'Cognome');


        gui.AggiungiCampoFormHidden(tipo => 'number', nome => 'id_ses', value => id_ses);

        gui.AggiungiCampoFormFiltro(tipo => 'submit', nome => '', placeholder => 'Filtra');

        gui.chiudiFormFiltro();
        gui.ACAPO();

        g2S.resetFilter(url => '.visualizzaCorseNPAutista', id_ses => id_ses);

        head:=gui.StringArray('Matricola','Nome','Cognome', 'Numero Corse Effettuate', ' ');
        gui.ApriTabella(head);


        v_query_sql:='CREATE OR REPLACE VIEW CorseNPAutista AS
            SELECT d.Matricola, d.Nome, d.Cognome, COUNT(*) as NumeroCorse
            FROM CorseNonPrenotate cnp, TaxiStandard ts, Taxi t, Turni tu, Autisti a, Dipendenti d
            WHERE
                cnp.FK_Standard = ts.FK_Taxi AND
                ts.FK_Taxi = t.IDtaxi AND
                tu.FK_Taxi = t.IDtaxi AND
                tu.FK_Autista = a.FK_Dipendente AND
                a.FK_Dipendente = d.Matricola AND
                cnp.DataOra >= tu.DataOraInizio AND
                cnp.DataOra <= tu.DataOraFine';

        --data min
        IF a_Data_min IS NOT NULL THEN
            v_query_sql := v_query_sql || ' AND (TO_DATE(''' || a_Data_min || ''', ''YYYY-MM-DD'') <= TRUNC(cnp.DataOra))';
        END IF;
        --data max
        IF a_Data_max IS NOT NULL THEN
            v_query_sql := v_query_sql || ' AND (TO_DATE(''' || a_Data_max || ''', ''YYYY-MM-DD'') >= TRUNC(cnp.DataOra))';
        END IF;
        --ora min
        IF a_Ora_min IS NOT NULL THEN
            v_query_sql := v_query_sql || ' AND TO_CHAR(cnp.DataOra, ''HH24:MI'') >= ''' || a_Ora_min || '''';
        END IF;
        --ora max
        IF a_Ora_max IS NOT NULL THEN
            v_query_sql := v_query_sql || ' AND TO_CHAR(cnp.DataOra, ''HH24:MI'') <= ''' || a_Ora_max || '''';
        END IF;
        --durata min
        IF a_Durata_min IS NOT NULL THEN
            v_query_sql := v_query_sql || ' AND cnp.Durata >= ''' || a_Durata_min || '''';
        END IF;
        --durata max
        IF a_Durata_max IS NOT NULL THEN
            v_query_sql := v_query_sql || ' AND cnp.Durata <= ''' || a_Durata_max || '''';
        END IF;
        --importo min
        IF a_Importo_min IS NOT NULL THEN
            v_query_sql := v_query_sql || ' AND cnp.Importo >=''' || a_Importo_min || '''';
        END IF;
        --importo max
        IF a_Importo_max IS NOT NULL THEN
            v_query_sql := v_query_sql || ' AND cnp.Importo <= ''' || a_Importo_max || '''';
        END IF;

        v_query_sql := v_query_sql || ' GROUP BY d.Matricola, d.Nome, d.Cognome';

        EXECUTE IMMEDIATE v_query_sql;

        IF (sessionhandler.getruolo(id_ses)='Contabile' OR sessionhandler.getruolo(id_ses)='Manager' )--da rivdere chi può
        THEN
        for x in( SELECT *
                FROM CorseNPAutista
                WHERE
                --num Corse Min
                (a_NumCorseMin<=NumeroCorse or a_NumCorseMin is null) AND
                --num Corse Max
                (a_NumCorseMax>=NumeroCorse or a_NumCorseMax is null) AND
                --matricola
                (a_Matricola = Matricola or a_Matricola is null) AND
                --nome
                (LOWER(replace(Nome, ' ', '')) LIKE '%'||(LOWER(replace(a_Nome, ' ', '')))||'%' or a_Nome is null) AND
                --cognome
                (LOWER(replace(Cognome, ' ', '')) LIKE '%'||(LOWER(replace(a_Cognome, ' ', '')))||'%' or a_Cognome is null)
        )
        loop
            -- Esegui le operazioni sui dati recuperati
            gui.AggiungiRigaTabella();
            gui.AggiungiElementoTabella(x.Matricola  || '');
            gui.AggiungiElementoTabella(x.Nome  || '');
            gui.AggiungiElementoTabella(x.Cognome  || '');
            gui.AggiungiElementoTabella(x.NumeroCorse  || '');
            gui.apriElementoPulsanti;
            gui.AggiungiPulsanteGenerale(testo => 'Visualizza Autista',
                                         collegamento => ''''||link || '' ||u_user||'.gruppo4.visualizzaDipendente?idSessione=' || id_ses
                                                            || chr(38) || 'IMatricola='||x.Matricola||'''');
            gui.chiudiElementoPulsanti;
            gui.ChiudiRigaTabella();
        END LOOP;

        gui.ChiudiTabella();
        END IF;
        gui.CHIUDIPAGINA();

    END visualizzaCorseNPAutista;

    PROCEDURE visualizzaBestCNPAutista(
        id_ses in SessioniDipendenti.IDSessione%type,
        a_Matricola in Dipendenti.Matricola%type default null,
        a_Nome in Dipendenti.Nome%type default null,
        a_Cognome in Dipendenti.Cognome%type default null,
        a_NumCorseMin in Number default null,
        a_NumCorseMax in Number default null,
        a_Data_min in varChar2 default null,
        a_Data_max in varChar2 default null,
        a_Ora_min in varChar2 default null,
        a_Ora_max in varChar2 default null,
        a_Durata_min in CorseNonPrenotate.Durata%type default null,
        a_Durata_max in CorseNonPrenotate.Durata%type default null,
        a_Importo_min in CorseNonPrenotate.Importo%type default null,
        a_Importo_max in CorseNonPrenotate.Importo%type default null
    )is
    head gui.StringArray;
    Max_num_corse CorseNPAutista.numeroCorse%type;
    begin

        g2S.initialization(id_ses,'visualizzaBestCNPAutista','I migliori autisti per corse non prenotate, secondo i filtri ');

        gui.BOTTONEAGGIUNGI(testo=>'Back to visualizza Corse NP per autista', url=>u_root || '.visualizzaCorseNPAutista?id_ses='||id_ses||
                                                                                        '' ||chr(38) || 'a_Matricola=' || a_Matricola ||
                                                                                        '' ||chr(38) || 'a_Nome=' || a_Nome ||
                                                                                        '' ||chr(38) || 'a_Cognome=' || a_Cognome ||
                                                                                        '' ||chr(38) || 'a_NumCorseMin=' || a_NumCorseMin ||
                                                                                        '' ||chr(38) || 'a_NumCorseMax=' || a_NumCorseMax ||
                                                                                        '' ||chr(38) || 'a_Data_min=' || a_Data_min ||
                                                                                        '' ||chr(38) || 'a_Data_max=' || a_Data_max ||
                                                                                        '' ||chr(38) || 'a_Ora_min=' || a_Ora_min ||
                                                                                        '' ||chr(38) || 'a_Ora_max=' || a_Ora_max ||
                                                                                        '' ||chr(38) || 'a_Durata_min=' || a_Durata_min ||
                                                                                        '' ||chr(38) || 'a_Durata_max=' || a_Durata_max ||
                                                                                        '' ||chr(38) || 'a_Importo_min=' || a_Importo_min ||
                                                                                        '' ||chr(38) || 'a_Importo_max=' || a_Importo_max );

        SELECT MAX(numeroCorse) into Max_num_corse
        FROM CorseNPAutista
        WHERE a_NumCorseMax>=numeroCorse or a_NumCorseMax is null;

        IF Max_num_corse IS NOT NULL THEN

        head:=gui.StringArray('Matricola','Nome','Cognome', 'Numero Corse Effettuate', ' ');
        gui.ApriTabella(head);

        for x in (
            SELECT *
            FROM CorseNPAutista
            WHERE numeroCorse = Max_num_corse
        )
        loop
        gui.AggiungiRigaTabella();
            gui.AggiungiElementoTabella(x.Matricola  || '');
            gui.AggiungiElementoTabella(x.Nome  || '');
            gui.AggiungiElementoTabella(x.Cognome  || '');
            gui.AggiungiElementoTabella(x.NumeroCorse  || '');
            gui.apriElementoPulsanti;
            gui.AggiungiPulsanteGenerale(testo => 'Visualizza Autista',
                                         collegamento => ''''||link || '' ||u_user||'.gruppo4.visualizzaDipendente?idSessione=' || id_ses
                                                            || chr(38) || 'IMatricola='||x.Matricola||'''');
            gui.chiudiElementoPulsanti;
            gui.ChiudiRigaTabella();
        END LOOP;

        gui.ChiudiTabella();
        ELSE  gui.AggiungiIntestazione('Non sono state effettuate corse secondo i filtri selezionati', 'h3');
        END IF;
        gui.CHIUDIPAGINA();

    END visualizzaBestCNPAutista;

    PROCEDURE  utilizzoTaxi(
        id_ses in SessioniDipendenti.IDSessione%type,
        t_targa in TAXI.Targa%type default null,
        t_tipo in varchar2 default null
    )is
    targaTaxi TAXI.targa%type;
    usoTaxiS UtilizzoTaxiStandard.uso%type;
    tipoStandard NUMBER;
    tipoAccessibili NUMBER;
    tipoLusso NUMBER;
    begin

        -- INIZIALIZZAZIONE PAGINA
        IF SessionHandler.getRuolo(id_ses) = 'Cliente' OR SessionHandler.getRuolo(id_ses) = 'Contabile' THEN
            gui.ApriPagina('visualizzaTaxi', id_ses);
            gui.AGGIUNGIPOPUP(false,'Non hai il permesso per accedere a questa pagina', costanti.url||'gui.homePage?idSessione='||id_ses);
            return;
        end if;

        -- SELECT PER OPERAZIONE STATISTICA
        SELECT ROUND(PercentualeStandard, 2), ROUND(PercentualeAccessibili, 2), ROUND(PercentualeLusso, 2) INTO tipoStandard, tipoAccessibili, tipoLusso
        FROM PercentualeUtilizzoTaxi;

        if t_tipo = 'STANDARD'  and (SESSIONHANDLER.getruolo(id_ses) = 'Manager' or SESSIONHANDLER.getruolo(id_ses) = 'Autista')  then
            g2s.INITIALIZATION(id_ses, 'UtilizzoTaxiStandard', 'Uso Dei Taxi Standard');
            gui.AggiungiIntestazione('I taxi standard sono stati utilizzati per il ' || tipoStandard || '%', 'h3');
            gui.bottoneaggiungi('Back To visualizzaTaxi', url => u_root || '.visualizzaTaxi?id_ses=' || id_ses);
            gui.acapo();
            gui.ApriFormFiltro(u_root || '.UtilizzoTaxi');
            gui.AggiungiCampoFormFiltro('text', 't_targa', '', 'Targa');
            gui.AggiungiCampoFormFiltro(tipo => 'submit', nome => '', value => 'Filtra', placeholder => 'Filtra');
            gui.AGGIUNGICAMPOFORMHIDDEN(tipo => 'hidden', nome => 'id_ses', value => id_ses);
            GUI.AGGIUNGICAMPOFORMHIDDEN('hidden', 't_tipo', t_tipo);
            gui.chiudiFormFiltro();
            gui.ACAPO();
            g2S.resetFilter(url => '.UtilizzoTaxi', id_ses => id_ses, t_tipo => t_tipo);
            gui.acapo();
            gui.APRITABELLA(gui.StringArray('Targa', 'Uso'));
            if t_targa is not null then
                for i in (
                    select us.targa, us.uso
                    from UTILIZZOTAXISTANDARD us
                    where (UPPER(replace(us.Targa, ' ','')) LIKE '%' || UPPER(replace(t_targa,' ','')) || '%' or t_targa is null))
            loop
                    gui.AggiungiRigaTabella();
                    gui.AggiungiElementoTabella('' || i.targa || '');
                    gui.aggiungielementotabella('' || i.uso || '');
                    gui.ChiudiRigaTabella();
            end loop;
            else
                for i in (SELECT us.Targa, us.Uso
                          FROM UtilizzoTaxiStandard us)
                loop
                    gui.AggiungiRigaTabella();
                    gui.AggiungiElementoTabella('' || i.Targa || '');
                    gui.aggiungielementotabella('' || i.Uso || '');
                    gui.ChiudiRigaTabella();
                end loop;
            end if;
            gui.ChiudiTabella();
        end if;
        if t_tipo = 'ACCESSIBILI' and (SESSIONHANDLER.getruolo(id_ses) = 'Manager' or SESSIONHANDLER.getruolo(id_ses) = 'Autista') then
            g2s.INITIALIZATION(id_ses, 'UtilizzoTaxiAccessibili', 'Uso Dei Taxi Accessibili');
            gui.AggiungiIntestazione('I taxi accessibili sono stati utilizzati per il ' || tipoAccessibili || '%', 'h3');
            gui.bottoneaggiungi('Back To visualizzaTaxi', url => u_root || '.visualizzaTaxi?id_ses=' || id_ses);
            gui.acapo();
            gui.ApriFormFiltro(u_root || '.UtilizzoTaxi');
            gui.AggiungiCampoFormFiltro('text', 't_targa', '', 'Targa');
            gui.AggiungiCampoFormFiltro(tipo => 'submit', nome => '', value => 'Filtra', placeholder => 'Filtra');
            gui.AGGIUNGICAMPOFORMHIDDEN(tipo => 'hidden', nome => 'id_ses', value => id_ses);
            GUI.AGGIUNGICAMPOFORMHIDDEN('hidden', 't_tipo', t_tipo);
            gui.chiudiFormFiltro();
            gui.ACAPO();
            g2S.resetFilter(url => '.UtilizzoTaxi', id_ses => id_ses, t_tipo => t_tipo);
            gui.acapo();
            gui.APRITABELLA(gui.StringArray('Targa', 'Uso'));
            if t_targa is not null then
                for i in (
                    select ua.targa, ua.uso
                    from UTILIZZOTAXIACCESSIBILI ua
                    where (UPPER(replace(ua.Targa, ' ','')) LIKE '%' || UPPER(replace(t_targa,' ','')) || '%' or t_targa is null))
            loop
                    gui.AggiungiRigaTabella();
                    gui.AggiungiElementoTabella('' || i.targa || '');
                    gui.aggiungielementotabella('' || i.uso || '');
                    gui.ChiudiRigaTabella();
            end loop;
            else
                for i in (SELECT ua.Targa, ua.Uso
                          FROM UtilizzoTaxiAccessibili ua)
                loop
                    gui.AggiungiRigaTabella();
                    gui.AggiungiElementoTabella('' || i.Targa || '');
                    gui.aggiungielementotabella('' || i.Uso || '');
                    gui.ChiudiRigaTabella();
                end loop;
            end if;
            gui.ChiudiTabella();
        end if;
        if t_tipo = 'LUSSO' and (SESSIONHANDLER.getruolo(id_ses) = 'Manager' or SESSIONHANDLER.getruolo(id_ses) = 'Autista') then
            g2s.INITIALIZATION(id_ses, 'UtilizzoTaxiLusso', 'Uso Dei Taxi Lusso');
            gui.AggiungiIntestazione('I taxi lusso sono stati utilizzati per il ' || tipoLusso || '%', 'h3');
            gui.bottoneaggiungi('Back To visualizzaTaxi', url => u_root || '.visualizzaTaxi?id_ses=' || id_ses);
            gui.acapo();
            gui.ApriFormFiltro(u_root || '.UtilizzoTaxi');
            gui.AggiungiCampoFormFiltro('text', 't_targa', '', 'Targa');
            gui.AggiungiCampoFormFiltro(tipo => 'submit', nome => '', value => 'Filtra', placeholder => 'Filtra');
            gui.AGGIUNGICAMPOFORMHIDDEN(tipo => 'hidden', nome => 'id_ses', value => id_ses);
            gui.AGGIUNGICAMPOFORMHIDDEN(tipo => 'hidden', nome => 't_tipo', value => t_tipo);
            gui.chiudiFormFiltro();
            gui.ACAPO();
            g2S.resetFilter(url => '.UtilizzoTaxi', id_ses => id_ses, t_tipo => t_tipo);
            gui.acapo();
            gui.APRITABELLA(gui.StringArray('Targa', 'Uso'));
            if t_targa is not null then
                for i in (
                    select ul.targa, ul.uso
                    from UTILIZZOTAXILUSSO ul
                    where (UPPER(replace(ul.Targa, ' ','')) LIKE '%' || UPPER(replace(t_targa,' ','')) || '%' or t_targa is null))
            loop
                    gui.AggiungiRigaTabella();
                    gui.AggiungiElementoTabella('' || i.targa || '');
                    gui.aggiungielementotabella('' || i.uso || '');
                    gui.ChiudiRigaTabella();
            end loop;
            else
                for i in (SELECT ul.Targa, ul.Uso
                          FROM UtilizzoTaxiLusso ul)
                loop
                    gui.AggiungiRigaTabella();
                    gui.AggiungiElementoTabella('' || i.Targa || '');
                    gui.aggiungielementotabella('' || i.Uso || '');
                    gui.ChiudiRigaTabella();
                end loop;
            end if;
            gui.ChiudiTabella();
        end if;
        gui.acapo(2);
        gui.chiudipagina();
    end utilizzoTaxi;

    PROCEDURE VisualizzaUsoTaxiAutista(
        id_ses in SessioniDipendenti.IDSessione%type,
        a_Matricola in Dipendenti.Matricola%type default null,
        a_Nome in Dipendenti.Nome%type default null,
        a_Cognome in Dipendenti.Cognome%type default null,
        at_CorseMin in UtilizzoTaxiAutista.NumeroCorse%type default null,
        at_CorseMax in UtilizzoTaxiAutista.NumeroCorse%type default null,
        t_Targa in Taxi.Targa%type default null
    )IS
        query VARCHAR2(1000);
        head gui.StringArray;
    begin
        IF SessionHandler.getRuolo(id_ses) != 'Manager' THEN
            gui.ApriPagina('visualizzaCorseNonPrenotate', id_ses);
            gui.AGGIUNGIPOPUP(false,'Non hai il permesso per accedere a questa pagina', costanti.url||'gui.homePage?idSessione='||id_ses);
            return;
        end if;

        g2S.initialization(id_ses,'VisualizzaUsoTaxiAutista','Visualizzazione corse effettuate da ogni autista con un determinato taxi');

        gui.BOTTONEAGGIUNGI(testo=>'Back to visualizza Corse NP', url=>u_root || '.visualizzaCorseNonPrenotate?id_ses='||id_ses);
        gui.acapo();
        gui.acapo();
        gui.acapo();
        -- FORM
        gui.ApriFormFiltro(u_root || '.VisualizzaUsoTaxiAutista');
        gui.aCapo();

        gui.AggiungiCampoFormFiltro(tipo => 'number', nome => 'at_CorseMin', value => at_CorseMin, placeholder => 'Minimo Numero Corse');
        gui.AggiungiCampoFormFiltro(tipo => 'number', nome => 'at_CorseMax', value => at_CorseMax, placeholder => 'Massimo Numero Corse');
        gui.AggiungiCampoFormFiltro(tipo => 'text', nome => 't_Targa', value => t_Targa, placeholder => 'Targa');
        gui.AggiungiCampoFormFiltro(tipo => 'number', nome => 'a_Matricola', value => a_Matricola, placeholder => 'Matricola');
        gui.AggiungiRigaTabella();
        gui.AggiungiCampoFormFiltro(tipo => 'text', nome => 'a_Nome', value => a_Nome, placeholder => 'Nome');
        gui.AggiungiCampoFormFiltro(tipo => 'text', nome => 'a_Cognome', value => a_Cognome, placeholder => 'Cognome');

        gui.AggiungiCampoFormHidden(tipo => 'number', nome => 'id_ses', value => id_ses);

        gui.AggiungiCampoFormFiltro(tipo => 'submit', nome => '', placeholder => 'Filtra');

        gui.chiudiFormFiltro();
        gui.ACAPO();

        g2S.resetFilter(url => '.VisualizzaUsoTaxiAutista', id_ses => id_ses);

        head:=gui.StringArray('Matricola','Nome','Cognome', 'Taxi', 'Targa', 'Numero Corse Effettuate', ' ');
        gui.ApriTabella(head);

        
        for riga in(SELECT *
                    FROM UtilizzoTaxiAutista uta
                    WHERE
                    --num Corse Min
                    (at_CorseMin<=uta.NumeroCorse or at_CorseMin is null) AND
                    --num Corse Max
                    (at_CorseMax>=uta.NumeroCorse or at_CorseMax is null) AND
                    --matricola
                    (a_Matricola = uta.Matricola or a_Matricola is null) AND
                    --nome
                    (LOWER(replace(uta.Nome, ' ', '')) LIKE '%'||(LOWER(replace(a_Nome, ' ', '')))||'%' or a_Nome is null) AND
                    --cognome
                    (LOWER(replace(uta.Cognome, ' ', '')) LIKE '%'||(LOWER(replace(a_Cognome, ' ', '')))||'%' or a_Cognome is null) AND
                    --taxi
                    (t_targa = uta.Targa or t_targa is null)
        )
        loop
            -- Esegui le operazioni sui dati recuperati
            gui.AggiungiRigaTabella();
            gui.AggiungiElementoTabella(riga.Matricola  || '');
            gui.AggiungiElementoTabella(riga.Nome  || '');
            gui.AggiungiElementoTabella(riga.Cognome  || '');
            gui.AggiungiElementoTabella(riga.IDtaxi  || '');
            gui.AggiungiElementoTabella(riga.Targa  || '');
            gui.AggiungiElementoTabella(riga.NumeroCorse  || '');
            gui.apriElementoPulsanti;
            gui.AggiungiPulsanteGenerale(testo => 'Visualizza Autista',
                                        collegamento => ''''||link || '' ||u_user||'.gruppo4.visualizzaDipendente?idSessione=' || id_ses
                                                            || chr(38) || 'IMatricola='||riga.Matricola||'''');
            gui.chiudiElementoPulsanti;
            gui.ChiudiRigaTabella();
        END LOOP;

        gui.ChiudiTabella();
        gui.CHIUDIPAGINA();
    END VisualizzaUsoTaxiAutista;
end gruppo2;