        --SET DEFINE OFF;

        create or replace PACKAGE BODY Gruppo3 as

        --registrazioneCliente : procedura che instanzia la pagina HTML adibita al ruolo di far registrare il cliente al sito
            procedure registrazioneCliente (
                err_popup varchar2 default null
            ) IS
            BEGIN

            gui.APRIPAGINA(titolo => 'Registrazione');

            if err_popup is not null then

                --cliente già presente
                if err_popup = 'D' then
                        gui.AggiungiPopup(False, 'Registrazione fallita, cliente già presente sul sito!');
                        gui.aCapo(2);
                    end if;

                    --dataNascita
                    if err_popup = 'B' then
                        gui.AggiungiPopup(False, 'Data di nascita non valida!');
                        gui.aCapo(2);
                    end if;

                    --password
                    if err_popup = 'P' then
                        gui.AggiungiPopup(False, 'Password troppo corta! Deve essere di almeno 8 caratteri');
                        gui.aCapo(2);
                    end if;
            end if;

            gui.AGGIUNGIFORM (url => u_root || '.inserisciDati');


                    gui.aggiungiIntestazione(testo => 'Registrazione');
                    gui.acapo;
                    gui.AGGIUNGIGRUPPOINPUT;
                        gui.aggiungiIntestazione(testo => 'Informazioni personali', dimensione => 'h2');
                        gui.AGGIUNGICAMPOFORM (classeIcona => 'fa fa-user', nome => 'Nome', placeholder => 'Nome');
                        gui.AGGIUNGICAMPOFORM (classeIcona => 'fa fa-user', nome => 'Cognome', placeholder => 'Cognome');
                        gui.AGGIUNGICAMPOFORM (tipo => 'email', classeIcona => 'fa fa-envelope', nome => 'Email', placeholder => 'Indirizzo Email');
                        gui.AGGIUNGICAMPOFORM (tipo => 'password', classeIcona => 'fa fa-key', nome => 'Password', placeholder => 'Password');
                        gui.AGGIUNGICAMPOFORM (tipo => 'number', classeIcona => 'fa fa-phone', nome => 'Telefono', placeholder => 'Telefono');
                    gui.CHIUDIGRUPPOINPUT;


                gui.aggiungiGruppoInput;
                    gui.APRIDIV (classe => 'col-half');
                        gui.aggiungiIntestazione(testo => 'Data di nascita', dimensione => 'h4');

                            gui.APRIDIV (classe => 'col-third');
                                gui.AGGIUNGIINPUT (placeholder => 'DD', nome => 'Day', classe => '');
                            gui.CHIUDIDIV;

                            gui.APRIDIV (classe => 'col-third');
                                gui.AGGIUNGIINPUT (placeholder => 'MM', nome => 'Month', classe => '');
                            gui.CHIUDIDIV;

                            gui.APRIDIV (classe => 'col-third');
                                gui.AGGIUNGIINPUT (placeholder => 'YYYY', nome => 'Year', classe => '');
                            gui.CHIUDIDIV;
                        gui.chiudiDiv;

                            gui.APRIDIV (classe => 'col-half');
                                gui.aggiungiIntestazione(testo => 'Sesso', dimensione => 'h4');

                            gui.AGGIUNGIGRUPPOINPUT;
                                gui.AGGIUNGIINPUT (nome => 'gender', ident => 'gender-male', tipo => 'radio', value => 'M');
                                gui.AGGIUNGILABEL (target => 'gender-male', testo => 'Maschio');
                                gui.AGGIUNGIINPUT (nome => 'gender', ident => 'gender-female', tipo => 'radio', value => 'F');
                                gui.AGGIUNGILABEL (target => 'gender-female', testo => 'Femmina');
                            gui.CHIUDIGRUPPOINPUT;
                        gui.CHIUDIDIV;

                gui.CHIUDIGRUPPOINPUT;

                    gui.AGGIUNGIGRUPPOINPUT;
                            gui.aggiungiBottoneSubmit (value => 'Registra');
                    gui.CHIUDIGRUPPOINPUT;
                gui.CHIUDIFORM;
                GUI.ACAPO(2);
            gui.ChiudiPagina;

            END registrazioneCliente;

        --inserisciDati : procedura che prende i dati dal form di registrazioneCliente e provvede a inserire i dati nella tabella
            procedure inserisciDati (Nome VARCHAR2 DEFAULT NULL,
            Cognome VARCHAR2 DEFAULT NULL,
            Email VARCHAR2 DEFAULT NULL,
            Password VARCHAR2 DEFAULT NULL,
            Telefono VARCHAR2 DEFAULT NULL,
            Day VARCHAR2 DEFAULT NULL,
            Month VARCHAR2 DEFAULT NULL,
            Year VARCHAR2 DEFAULT NULL,
            Gender VARCHAR2 DEFAULT NULL) IS

            DataNascita DATE;
            Sesso CHAR(1);

            begin
                DataNascita := TO_DATE (Day || '/' || Month || '/' || Year, 'DD-MM-YYYY');
                Sesso := SUBSTR(Gender, 1, 1);  -- cast da varchar2 a char(1)

                --data di nascita non valida
                if DataNascita > SYSDATE then
                    gui.reindirizza (u_root || '.registrazioneCliente?err_popup=B');
                    return;
                end if;

                --password troppo corta
                if length (Password) < 8 then
                    gui.reindirizza (u_root || '.registrazioneCliente?err_popup=P');
                    return;
                end if;

                INSERT INTO CLIENTI (Nome, Cognome, DataNascita, Sesso, NTelefono, Email, Password, Stato, Saldo)
                VALUES (Nome, Cognome, DataNascita, Sesso, TO_NUMBER(Telefono),Email,Password,1,0);

                --se l'inserimento va a buon fine, apro la pagina di login

                gui.HomePage (p_registrazione => true);

            EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                --visualizza popup di errore
                gui.reindirizza (u_root || '.registrazioneCliente?err_popup=D');
            end inserisciDati;

        --inserimentoConvenzione :form per la insert della convenzione
        PROCEDURE inserisciConvenzione(
            idSess varchar, 
            popup varchar2 default null
        ) IS
        BEGIN

            gui.APRIPAGINA(titolo => 'Inserimento Convenzione', idSessione => idSess);

            if NOT (SESSIONHANDLER.checkRuolo (idSess, 'Manager')) then
                gui.aggiungiPopup (False, 'Non hai i permessi per accedere a questa pagina', costanti.URL || 'gui.homepage?p_success=S&idSessione='||idSess||'');
                gui.chiudiPagina;
            return;
            end if;

            
            if popup IS NOT NULL then
                if popup = 'S' then
                    gui.aggiungiPopup (True, 'Convenzione inserita'); 
                    gui.aCapo;
                end if; 
                if popup = 'D' then 
                    gui.aggiungiPopup (False, 'Nome o codice accesso già usati'); 
                    gui.aCapo;
                end if;  
            end if; 

            gui.AGGIUNGIFORM (url => u_root || '.inseriscidatiConvenzione');
            -- Inserimento dei campi del modulo
            gui.aggiungiIntestazione(testo => 'Inserimento Convenzione');
            gui.aCapo();
            gui.AggiungiGruppoInput;
            gui.aggiungiIntestazione (testo => 'Info', dimensione => 'h2');
            gui.aggiungiInput (tipo => 'hidden', value => idSess, nome => 'idSess');
            gui.AggiungiCampoForm(classeIcona => 'fa fa-user', nome => 'r_nome', placeholder => 'Nome');
            gui.AggiungiCampoForm(classeIcona => 'fa fa-user', nome => 'r_ente', placeholder => 'Ente');
            gui.AggiungiCampoForm(tipo => 'number', classeIcona => 'fa fa-money-bill', nome => 'r_sconto', placeholder => 'Sconto');
            gui.AggiungiCampoForm(classeIcona => 'fa fa-lock', nome => 'r_codiceAccesso', placeholder => 'Codice Accesso');
            gui.ChiudiGruppoInput;


            gui.AGGIUNGIGRUPPOINPUT;
                gui.aggiungiIntestazione (testo => 'Data inizio', dimensione => 'h2');
                gui.AggiungiCampoForm(tipo => 'date', nome => 'r_dataInizio', placeholder => 'Data Inizio');
                gui.aggiungiIntestazione (testo => 'Data fine', dimensione => 'h2');
                gui.AggiungiCampoForm(tipo => 'date', nome => 'r_dataFine', placeholder => 'Data Fine');
                gui.aggiungiIntestazione (testo => 'Cumulabile', dimensione => 'h2');
                gui.aggiungiSelezioneSingola (elementi => gui.StringArray ('Si', 'No'), valoreEffettivo => gui.StringArray('1','0'), ident => 'r_cumulabile', optionSelected => '0'); 
                
            gui.chiudiGruppoInput;

            -- Bottone di submit per inviare il modulo
            gui.AGGIUNGIGRUPPOINPUT;
            gui.AggiungiBottoneSubmit(value => 'Inserisci');
            gui.ChiudiGruppoInput;


            -- Chiusura del modulo
                gui.ChiudiForm;
                gui.aCapo(2);
            gui.ChiudiPagina;

        END inserisciConvenzione;

        --procedura per la insert convenzione nel form (adesso funziona, bisogna settare le sessioni e i relativi controlli)
        procedure inseriscidatiConvenzione (
                idSess          varchar2,
                r_nome          varchar2 default null,
                r_ente          varchar2 default null,
                r_sconto        varchar2 default null,
                r_codiceAccesso varchar2 default null,
                r_dataInizio    varchar2 default null,
                r_dataFine      varchar2 default null,
                r_cumulabile    varchar2 default null
        ) IS
        BEGIN

            -- Apre una pagina di registrazione
            gui.ApriPagina('Inserimento Convenzione', idSessione => idSess);

            -- Inserimento dei dati nella tabella CONVENZIONI
            INSERT INTO CONVENZIONI (Nome, Ente, Sconto, CodiceAccesso, DataInizio, DataFine, Cumulabile)
            VALUES (r_nome, r_ente, TO_NUMBER(r_sconto), r_codiceAccesso, TO_DATE(r_dataInizio,'(YYYY/MM/DD)'), TO_DATE(r_dataFine,'YYYY/MM/DD'), r_cumulabile);

            -- Messaggio di conferma dell'inserimento
            gui.reindirizza (u_root||'.inserisciConvenzione?idSess='||idSess||'&popUp=S');

            EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN 
            gui.reindirizza (u_root||'.inserisciConvenzione?idSess='||idSess||'&popUp=D');

            END inseriscidatiConvenzione;

            procedure associaConvenzione (
                idSess SESSIONICLIENTI.IDSESSIONE%TYPE default null, --CLIENTE
                c_Codice varchar2 default null,
                err_popup varchar2 default null
            ) IS
                data_fine CONVENZIONI.DATAFINE%TYPE := NULL;
                data_inizio CONVENZIONI.DATAINIZIO%TYPE := NULL; 
                id_convenzione CONVENZIONI.IDCONVENZIONE%TYPE := NULL;
                c_check CONVENZIONICLIENTI.FK_CLIENTE%TYPE := NULL; --uso questa variabile per il controllo sulla convenzione già associata
            BEGIN
        
                gui.apriPagina (titolo => 'Associa convenzione', idSessione => idSess); --se l'utente non è loggato torna alla pagina di login

                --controllo che l'utente sia un cliente
                if (NOT SESSIONHANDLER.checkRuolo (idSess, 'Cliente')) then
                    gui.aggiungiPopup (FALSE, 'Non hai i permessi per accedere alla pagina!', costanti.URL || 'gui.homePage?idSessione='||idSess||'&p_success=S');
                    gui.chiudiPagina;
                    return;
                end if;

                if err_popup IS NOT NULL then

                    if err_popup = 'N' then --nodatafound : mandiamo il messaggio di errore 'convenzione non trovata'
                        gui.aggiungiPopup (False, 'Convenzione non trovata');
                        gui.acapo(2);
                    end if;

                    if err_popup = 'D' then --dupvalonindex : mandiamo il messaggio di errore 'convenzione già associata'
                        gui.aggiungiPopup (False, 'Convenzione già associata ad ' || SESSIONHANDLER.getUsername     (idSess)|| '');
                        gui.acapo(2);
                    end if; 

                end if; 

                --controllo sulla convenzione
                if  c_Codice IS NOT NULL then
                    SELECT IDCONVENZIONE,DATAFINE, DATAINIZIO INTO id_convenzione, data_fine, data_inizio FROM CONVENZIONI WHERE CODICEACCESSO = c_Codice;
                    if SQL%ROWCOUNT = 1 then --convenzione trovata

                    -- il controllo che la convenzione non sia già associata al cliente è implicito in quanto (fk_cliente, fk_convenzione) in 
                    --convenzioniClienti è primary key

                        --controllo convenzione scaduta o non ancora emessa
                        if data_fine < SYSDATE OR data_inizio > SYSDATE then
                            gui.aggiungiPopup (False, 'Convenzione scaduta , o non ancora pubblicata');
                            gui.aCapo(2);
                        else
                            INSERT INTO CONVENZIONICLIENTI (FK_CLIENTE, FK_CONVENZIONE) VALUES (SESSIONHANDLER.GETIDUSER(idSess), id_convenzione);
                            gui.aggiungiPopup (True, 'Convenzione associata');
                            gui.aCapo(2);
                            end if;
                    
                    end if;
                end if;

                gui.aggiungiForm;
                    gui.aggiungiInput (tipo => 'hidden', value => idSess, nome => 'idSess');
                    gui.aggiungiIntestazione(testo => 'Associa convenzione', dimensione => 'h2');
                    gui.aggiungiGruppoInput;
                        gui.bottoneAggiungi (testo => 'Torna indietro', url => u_root || '.visualizzaProfilo?idSess='||idSess||'');
                    gui.chiudiGruppoInput;

                    gui.acapo(2);

                    gui.aggiungiGruppoInput;
                        gui.AGGIUNGICAMPOFORM (classeIcona => 'fa fa-lock', nome => 'c_Codice', placeholder => 'Immetti il codice di accesso alla convenzione',ident => 'c_Codice',  required => true);
                    gui.chiudiGruppoInput;

                    gui.acapo();
                    gui.aggiungiGruppoInput;
                        gui.aggiungiBottoneSubmit (value => 'Associa');
                    gui.chiudiGruppoInput;

                gui.chiudiForm;

                gui.aCapo(3);
                gui.chiudiPagina;

                EXCEPTION
                WHEN NO_DATA_FOUND then
                    gui.REINDIRIZZA(u_root||'.associaConvenzione?idSess='||idSess||'&err_popUp=N');
                
                WHEN DUP_VAL_ON_INDEX then
                    gui.REINDIRIZZA(u_root||'.associaConvenzione?idSess='||idSess||'&err_popUp=D');
                
                END associaConvenzione;

            procedure modificaConvenzione (
                idSess varchar default null,
                c_id varchar2,
                c_sconto varchar2 default null,
                c_dataInizio varchar2 default null,
                c_dataFine varchar2 default null,
                c_cumulabile varchar2 default null
            ) IS
            current_sconto CONVENZIONI.SCONTO%TYPE := NULL;
            d_inizio CONVENZIONI.DATAINIZIO%TYPE := NULL;
            d_fine CONVENZIONI.DATAFINE%TYPE := NULL;
            error_check boolean := false;
            c int := 0;
            current_cumulabile CONVENZIONI.CUMULABILE%TYPE := NULL;

            BEGIN
                gui.apriPagina (titolo => 'Modifica convenzione', idSessione => idSess); --se l'utente non è loggato torna alla pagina di login

                --controllo che l'utente sia un manager
                if (NOT SESSIONHANDLER.checkRuolo (idSess, 'Manager')) then
                    gui.aggiungiPopup (FALSE, 'Non hai i permessi per accedere alla pagina!', costanti.URL || 'gui.homePage?idSessione='||idSess||'&p_success=S');
                    gui.chiudiPagina;
                    return;
                end if;

                --controlliamo che la convenzione sia modificabile (per essere modificabile non deve essere stata ancora pubblicata o essere scaduta)
                if c_id IS NOT NULL then
                    SELECT Sconto, DataInizio, DataFine, Cumulabile INTO current_sconto, d_inizio, d_fine, current_cumulabile FROM CONVENZIONI WHERE
                        IDCONVENZIONE = c_id;
                        if (d_fine < SYSDATE OR d_inizio < SYSDATE) then
                            gui.aggiungiPopup (FALSE, 'Convenzione scaduta o già pubblicata, perciò non modificabile!');
                            return; 
                        end if;
                end if;

                --gestione delle modifiche

                if c_sconto IS NOT NULL AND c_sconto <> current_sconto then
                    IF 0 < c_sconto AND c_sconto < 100 THEN --controllo parametro
                    UPDATE CONVENZIONI
                        SET SCONTO = c_Sconto
                        WHERE IDConvenzione = c_id;
                        c := c+1;
                        else
                        error_check:=true;
                        end if;
                end if;

                if c_dataInizio IS NOT NULL AND TO_DATE(c_dataInizio, 'YYYY-MM-DD') <> d_inizio then
                --controlli
                    if TO_DATE(c_dataInizio, 'YYYY-MM-DD') < SYSDATE then
                        error_check:=true;
                    elsif c_dataFine IS NOT NULL AND TO_DATE(c_dataFine, 'YYYY-MM-DD') <> d_fine then
                        if TO_DATE(c_dataInizio, 'YYYY-MM-DD') > TO_DATE(c_dataFine, 'YYYY-MM-DD') then
                            error_check:=true;
                        end if;
                    end if;

                    if NOT error_check then 
                        UPDATE CONVENZIONI
                            SET DATAINIZIO = TO_DATE(c_dataInizio, 'YYYY-MM-DD')
                            WHERE IDConvenzione = c_id;
                    c := c+1;

                    end if; 
                    
                end if;

                if c_dataFine IS NOT NULL AND TO_DATE(c_dataFine, 'YYYY-MM-DD') <> d_fine then
                --controlli
                    if TO_DATE(c_dataFine, 'YYYY-MM-DD') < SYSDATE then
                        error_check:=true;
                    end if;

                    if c_dataInizio IS NOT NULL AND TO_DATE(c_dataInizio, 'YYYY-MM-DD') <> d_inizio then
                            if TO_DATE(c_dataFine, 'YYYY-MM-DD') < TO_DATE(c_dataInizio, 'YYYY-MM-DD') then
                                error_check:=true;
                            end if;
                    end if;

                if NOT error_check then 
                    UPDATE CONVENZIONI
                    SET DATAFINE = TO_DATE(c_dataFine, 'YYYY-MM-DD')
                    WHERE IDConvenzione = c_id;
                    c:=c+1;
                    end if; 
             
                end if;

                if c_Cumulabile IS NOT NULL AND c_cumulabile <> current_cumulabile then       
                    UPDATE CONVENZIONI
                        SET CUMULABILE = c_cumulabile
                        WHERE IDConvenzione = c_id;
                        c:=c+1;
                end if;

                    IF error_check THEN
                        gui.aggiungiPopup (FALSE, 'Modifiche non accettate, controllare i parametri');
                        gui.acapo(2);
                    ELSE
                        IF c > 1 THEN
                            gui.aggiungiPopup (TRUE, 'Campi modificati');
                            gui.acapo(2);
                        ELSE
                            IF c = 1 THEN
                                gui.aggiungiPopup (TRUE, 'Campo modificato');
                                gui.acapo(2);
                            END IF;
                        END IF;
                    END IF;


                gui.aCapo(2);
                gui.aggiungiForm;

                gui.aggiungiGruppoInput;
                gui.aggiungiIntestazione (testo => 'Modifica convenzione'); 
                gui.chiudiGruppoInput; 
                gui.aCapo(2);


                gui.aggiungiInput (tipo => 'hidden', nome => 'idSess', value => idSess);
                gui.aggiungiInput (tipo => 'hidden', nome => 'c_id', value => c_id);

                    gui.aggiungiGruppoInput;
                        gui.AGGIUNGICAMPOFORM (classeIcona => 'fa fa-money-bill', nome => 'c_sconto', placeholder => 'Sconto',ident => 'c_sconto',  required => false);
                        gui.AGGIUNGIINTESTAZIONE (testo => 'Data di inizio', dimensione => 'h2');
                        gui.AGGIUNGICAMPOFORM (tipo => 'date', classeIcona => 'fa fa-envelope', nome => 'c_dataInizio', placeholder => 'Data di inizio convenzione',ident => 'c_dataInizio',  required => false);
                        gui.AGGIUNGIINTESTAZIONE (testo => 'Data di scadenza', dimensione => 'h2');
                        gui.AGGIUNGICAMPOFORM (tipo => 'date', classeIcona => 'fa fa-envelope', nome => 'c_dataFine', placeholder => 'Data di fine convenzione',ident => 'c_dataFine',  required => false);
                    gui.chiudiGruppoInput;

                    gui.aggiungiIntestazione(testo => 'Cumulabile', dimensione => 'h2');
                            gui.apriDiv(classe => 'row');
                                gui.AGGIUNGIGRUPPOINPUT;
                                    gui.AGGIUNGIINPUT (nome => 'c_cumulabile', ident => 'si', tipo => 'radio', value => '1');
                                    gui.AGGIUNGILABEL (target => 'si', testo => 'si');
                                    gui.AGGIUNGIINPUT (nome => 'c_cumulabile', ident => 'no', tipo => 'radio', value => '0');
                                    gui.AGGIUNGILABEL (target => 'no', testo => 'no');
                                    gui.AGGIUNGIINPUT (nome => 'c_cumulabile', ident => 'default', tipo => 'radio', value => current_cumulabile, selected => true); --valore di default non cumulabile (cambiare con valore originale della convenzione)
                                gui.CHIUDIGRUPPOINPUT;
                            gui.chiudiDiv;

                    gui.acapo();

                    gui.aggiungiGruppoInput;
                        gui.aggiungiBottoneSubmit (value => 'Modifica');
                        gui.acapo(3);
                        gui.bottoneAggiungi (url => u_root || '.visualizzaConvenzioni?idSess='||idSess||'', testo => 'Torna indietro');
                    gui.chiudiGruppoInput;

                gui.ChiudiForm;
                gui.aCapo(3);
                gui.chiudiPagina;

                END modificaConvenzione;

        --modificaCliente : procedura che instanzia la pagina HTML della modifica dati cliente
            procedure modificaCliente(
            idSess SESSIONICLIENTI.IDSESSIONE%TYPE DEFAULT NULL,
            cl_id VARCHAR2 DEFAULT NULL,
            cl_Email VARCHAR2 DEFAULT NULL,
            cl_Password VARCHAR2 DEFAULT NULL,
            cl_Telefono VARCHAR2 DEFAULT NULL,
            err_popup VARCHAR2 DEFAULT NULL
        ) IS

            current_email CLIENTI.Email%TYPE := NULL;
            current_telefono CLIENTI.Ntelefono%TYPE := NULL;
            current_password CLIENTI.Password%TYPE := NULL;
            popup BOOLEAN := false;
            passCheck EXCEPTION; 

            c INTEGER := 0;

            BEGIN   
            gui.APRIPAGINA(titolo => 'Modifica dati cliente', idSessione => idSess); --accedo alla pagina se sono loggato

            SAVEPOINT sp1; 
            --accedo alla pagina (se sono cliente o operatore)
            if NOT (SESSIONHANDLER.checkRuolo(idSess, 'Cliente')) then
                gui.aggiungiPopup (False, 'Non hai i permessi per accedere a questa pagina', costanti.URL || 'gui.homePage?idSessione='||idSess||'&p_success=S');
                gui.chiudiPagina;
                return;
            end if;

            --gestione errori tramite popup
            if err_popup IS NOT NULL then 
                if err_popup = 'P' then --errore sulla password
                    gui.aggiungiPopup (False, 'La password è troppo corta, deve essere di almeno 8 caratteri'); 
                    gui.aCapo(); 
                end if; 

                if err_popup = 'E' then --errore sulla email
                    gui.aggiungiPopup (False, 'Email già utilizzata da qualche altro cliente'); 
                    gui.aCapo(); 
                end if;
            end if; 


            --un cliente non può accedere alla pagina modificaCliente di un altro cliente
            if  SESSIONHANDLER.checkRuolo(idSess, 'Cliente') AND cl_id IS NOT NULL AND SESSIONHANDLER.getIDUSER(idSess)<>to_number(cl_id) then
                gui.aggiungiPopup (False, 'Non hai i permessi per accedere alla pagina di modifica di altri clienti', costanti.URL || 'gui.homePage?idSessione='||idSess||'&p_success=S');
                gui.chiudiPagina;
                return;
            end if;

                SELECT Email, Ntelefono, Password
                    INTO current_email, current_telefono, current_password
                        FROM CLIENTI
                            WHERE IDCLIENTE  = cl_id;

                -- Aggiornamento dell'email
            IF cl_Email IS NOT NULL AND cl_Email <> current_email THEN
                UPDATE CLIENTI
                SET Email = cl_Email
                WHERE IDcliente = cl_id;
                popup := true;
                c := c + 1;

            END IF;

            --aggiornamento password
            IF cl_Password IS NOT NULL AND cl_Password <> current_password THEN

                    --controllare che la password sia di almeno 8 caratteri
                    if LENGTH(cl_Password) < 8 then --si stampa l'errore
                    
                    ROLLBACK TO sp1; 
                    gui.REINDIRIZZA(u_root||'.modificaCliente?idSess='||idSess||'&cl_id='||sessionHandler.getIDUser(idSess)||'&err_popup=P');
                    return;

                    else 
                        UPDATE CLIENTI
                        SET Password = cl_Password
                            WHERE IDcliente = cl_id;
                    popup := true;
                    c := c + 1;
                    end if;             
            END IF;

                -- Aggiornamento del telefono
            IF cl_Telefono IS NOT NULL AND cl_Telefono <> current_telefono THEN
                UPDATE CLIENTI
                SET Ntelefono = cl_Telefono
                WHERE IDcliente = cl_id;

                popup := true;
                c := c + 1;
            END IF;

            --logica popup di successo
            if popup AND c>1 then
                gui.AGGIUNGIPOPUP (True , 'Campi modificati');
                gui.aCapo;
                else
                if popup AND c=1 then
                gui.AGGIUNGIPOPUP (True , 'Campo modificato');
                gui.aCapo;
                end if;
            end if;

            --ri-aggiorno i valori da visualizzare nella schermata
            SELECT Email, Ntelefono, Password
            INTO current_email, current_telefono, current_password
            FROM CLIENTI
            WHERE IDcliente = cl_id;


            gui.AGGIUNGIFORM;

            gui.aggiungiInput (tipo => 'hidden', nome => 'idSess', value => idSess);
            gui.aggiungiInput (tipo => 'hidden', nome => 'cl_id', value => cl_id);

            if SESSIONHANDLER.checkRuolo(idSess, 'Cliente') then
            gui.aggiungiIntestazione(testo => 'Modifica dati di', dimensione => 'h1');
            gui.aggiungiIntestazione(testo => SESSIONHANDLER.getUsername(idSess));
            end if;

            if SESSIONHANDLER.checkRuolo(idSess, 'Cliente') then
            gui.bottoneAggiungi (testo => 'Torna indietro', url => u_root || '.visualizzaProfilo?idSess='||idSess||'');
            gui.aCapo(2);
            end if;

            gui.AGGIUNGIGRUPPOINPUT;
                gui.AGGIUNGIINTESTAZIONE (testo => 'Email', dimensione => 'h2');
                gui.AGGIUNGIINTESTAZIONE (testo => 'Email corrente: ', dimensione => 'h3');
                gui.AGGIUNGIPARAGRAFO (testo => current_email);
                gui.AGGIUNGIINTESTAZIONE (testo => 'Nuova email: ', dimensione => 'h3');
                gui.AGGIUNGICAMPOFORM (tipo => 'email', classeIcona => 'fa fa-envelope', nome => 'cl_Email', placeholder => 'Nuova mail',ident => 'Email',  required => false);
            gui.CHIUDIGRUPPOINPUT;

            gui.AGGIUNGIGRUPPOINPUT;
                gui.AGGIUNGIINTESTAZIONE (testo => 'Password', dimensione => 'h2');
                gui.AGGIUNGIINTESTAZIONE (testo => 'Inserisci la nuova password', dimensione => 'h3');
                gui.AGGIUNGICAMPOFORM (tipo => 'password', classeIcona => 'fa fa-key', nome => 'cl_Password', placeholder => 'Password', ident => 'Password', required => false);
            gui.CHIUDIGRUPPOINPUT;

            gui.AGGIUNGIGRUPPOINPUT;
                gui.AGGIUNGIINTESTAZIONE (testo => 'Telefono', dimensione => 'h2');
                gui.AGGIUNGIINTESTAZIONE (testo => 'Vecchio numero : ', dimensione => 'h3');
                gui.AGGIUNGIPARAGRAFO (testo => current_telefono);
                gui.AGGIUNGIINTESTAZIONE (testo => 'Nuovo numero : ', dimensione => 'h3');
                gui.AGGIUNGICAMPOFORM (classeIcona => 'fa fa-phone', nome => 'cl_Telefono', placeholder => 'Telefono', ident => 'Telefono', required => false);
            gui.CHIUDIGRUPPOINPUT;

            gui.AGGIUNGIGRUPPOINPUT;
                        gui.aggiungiBottoneSubmit (value => 'Modifica');
            gui.CHIUDIGRUPPOINPUT;

            gui.CHIUDIFORM;
            gui.aCapo(2);
            gui.chiudiPagina;

            EXCEPTION
            WHEN NO_DATA_FOUND THEN
            gui.REINDIRIZZA(u_root||'.modificaCliente?idSess='||idSess||'&cl_id='||sessionHandler.getIDUser(idSess)||''); --mancava id cliente, reindirizziamo con l'id

            WHEN DUP_VAL_ON_INDEX THEN
            ROLLBACK TO sp1; 
            gui.REINDIRIZZA(u_root||'.modificaCliente?idSess='||idSess||'&cl_id='||sessionHandler.getIDUser(idSess)||'&err_popup=E'); --email già utilizzata

        END modificaCliente;

            procedure visualizzaProfilo (
                idsess SESSIONICLIENTI.IDSESSIONE%TYPE default null,
                id varchar2 default null
            ) is

            c_Nome varchar2(20);
            c_Cognome varchar2(20);
            c_DataNascita date;
            c_Telefono int;
            c_Email varchar2(50);
            c_Sesso char(1);
            c_Password varchar2(20);
            c_saldo int;

            BEGIN
                gui.apriPagina (titolo => 'Profilo', idSessione => idSess);

                if NOT (SESSIONHANDLER.checkRuolo (idSess, 'Cliente') OR SESSIONHANDLER.checkRuolo (idSess, 'Manager') OR SESSIONHANDLER.checkRuolo (idSess, 'Operatore')) then
                    gui.aggiungiPopup (False, 'Non hai i permessi per accedere a questa pagina', costanti.URL || 'gui.homePage?idSessione='||idSess||'&p_success=S');
                    gui.chiudiPagina;
                    return;
                end if;

                if (SESSIONHANDLER.checkRuolo (idSess, 'Cliente')) then
                    --prelevo i dati di cui ho bisogno tramite dalla sessione
                    SELECT Nome, Cognome, DataNascita, NTelefono, Email, Sesso, Password, Saldo INTO c_Nome, c_Cognome, c_DataNascita,
                    c_Telefono, c_Email, c_Sesso, c_Password, c_saldo FROM CLIENTI WHERE IDCLIENTE = SessionHandler.getIDuser (idSess);
                end if;

                if ((SESSIONHANDLER.checkRuolo (idSess, 'Manager') OR SESSIONHANDLER.checkRuolo (idSess, 'Operatore')) AND id IS NOT NULL) then
                    --prelevo le informazioni relative all'id del cliente passato per parametro al manager
                    SELECT Nome, Cognome, DataNascita, NTelefono, Email, Sesso, Password, Saldo INTO c_Nome, c_Cognome, c_DataNascita,
                    c_Telefono, c_Email, c_Sesso, c_Password, c_saldo FROM CLIENTI WHERE IDCLIENTE = id;
                end if;

                    gui.aggiungiForm;
                        --devo aggiungere i dati del cliente tramite sessionHandler

                        gui.aggiungiIntestazione (testo => 'Profilo di ');

                        if (SESSIONHANDLER.checkRuolo (idSess, 'Cliente')) then
                        gui.aggiungiIntestazione (testo => SessionHandler.GETUSERNAME (idSess));
                        else
                            if (SESSIONHANDLER.checkRuolo (idSess, 'Manager') OR SESSIONHANDLER.checkRuolo (idSess, 'Operatore')) then
                            gui.aggiungiIntestazione (testo => c_Nome); --già salvato il nome del cliente in precedenza
                            end if;
                        end if;

                        gui.aCapo(4);

                        gui.aggiungiGruppoInput;
                        gui.apriDiv (classe => 'flex-container');
                                    gui.apriDiv (classe => 'left');
                                        gui.aggiungiIntestazione (testo => 'Nome', dimensione => 'h2');
                                    gui.chiudiDiv;
                                    gui.apriDiv (classe => 'right');
                                        gui.aggiungiIntestazione (testo => c_Nome, dimensione => 'h2');
                                    gui.chiudiDiv;
                                    gui.apriDiv (classe => 'left');
                                        gui.aggiungiIntestazione (testo => 'Cognome', dimensione => 'h2');
                                    gui.chiudiDiv;
                                    gui.apriDiv (classe => 'right');
                                        gui.aggiungiIntestazione (testo => c_Cognome, dimensione => 'h2');
                                    gui.chiudiDiv;

                                    gui.apriDiv (classe => 'left');
                                        gui.aggiungiIntestazione (testo => 'Data di nascita', dimensione => 'h2');
                                    gui.chiudiDiv;
                                    gui.apriDiv (classe => 'right');
                                        gui.aggiungiIntestazione (testo => ''||c_DataNascita||'', dimensione => 'h2');
                                    gui.chiudiDiv;

                                    gui.apriDiv (classe => 'left');
                                        gui.aggiungiIntestazione (testo => 'Telefono', dimensione => 'h2');
                                    gui.chiudiDiv;
                                    gui.apriDiv (classe => 'right');
                                        gui.aggiungiIntestazione (testo => ''||c_Telefono||'', dimensione => 'h2');
                                    gui.chiudiDiv;

                                    gui.apriDiv (classe => 'left');
                                        gui.aggiungiIntestazione (testo => 'Email', dimensione => 'h2');
                                    gui.chiudiDiv;
                                    gui.apriDiv (classe => 'right');
                                        gui.aggiungiIntestazione (testo => c_Email, dimensione => 'h2');
                                    gui.chiudiDiv;

                                    --se chi entra nella pagina è Cliente, si visualizza la password
                                    if (SESSIONHANDLER.checkRuolo (idSess, 'Cliente')) then
                                        gui.apriDiv (classe => 'left');
                                        gui.aggiungiIntestazione (testo => 'Password', dimensione => 'h2');
                                    gui.chiudiDiv;
                                    gui.apriDiv (classe => 'right');
                                        gui.aggiungiIntestazione (testo => c_Password, dimensione => 'h2');
                                    gui.chiudiDiv;
                                    end if;

                                    gui.apriDiv (classe => 'left');
                                        gui.aggiungiIntestazione (testo => 'Saldo', dimensione => 'h2');
                                    gui.chiudiDiv;
                                    gui.apriDiv (classe => 'right');
                                        gui.aggiungiIntestazione (testo => c_Saldo || '€', dimensione => 'h2');
                                    gui.chiudiDiv;


                                    IF (SESSIONHANDLER.CheckRuolo(idSess, 'Cliente')) THEN
                                    gui.apriDiv(classe => 'left');
                                    gui.aggiungiIntestazione(testo => 'Convenzioni associate', dimensione => 'h2');
                                    gui.chiudiDiv;
                                    gui.apriDiv(classe => 'right');
                                    gui.aggiungiIntestazione(testo => ' ', dimensione => 'h2');
                                    gui.chiudiDiv;

                                    --visualizziamo le convenzioni associate
                                    FOR i IN (
                                        SELECT FK_CONVENZIONE FROM CONVENZIONICLIENTI WHERE FK_CLIENTE = SESSIONHANDLER.getIDUser(idSess)
                                    ) LOOP
                                        --prendiamo il nome e lo stampiamo
                                        for j IN (
                                            SELECT NOME FROM CONVENZIONI WHERE IDCONVENZIONE = i.FK_CONVENZIONE
                                        ) LOOP
                                            gui.apriDiv(classe => 'left');
                                            gui.aggiungiIntestazione(testo => ' ', dimensione => 'h2');
                                            gui.chiudiDiv;
                                            gui.apriDiv(classe => 'right');
                                            gui.aggiungiIntestazione(testo => j.NOME , dimensione => 'h2');
                                            gui.chiudiDiv;
                                        END LOOP;
                                    END LOOP;

                                    gui.apriDiv(classe => 'left');
                                    gui.aggiungiIntestazione(testo => 'Convenzioni attive', dimensione => 'h2');
                                    gui.chiudiDiv;
                                    gui.apriDiv(classe => 'right');
                                    gui.aggiungiIntestazione(testo => ' ', dimensione => 'h2');
                                    gui.chiudiDiv;

                                    --visualizziamo le convenzioni attive
                                    FOR i IN (
                                        SELECT FK_CONVENZIONE FROM CONVENZIONICLIENTI WHERE FK_CLIENTE = SESSIONHANDLER.getIDUser(idSess)
                                    ) LOOP
                                        --prendiamo il nome e lo stampiamo
                                        for j IN (
                                            SELECT NOME, DATAFINE FROM CONVENZIONI WHERE IDCONVENZIONE = i.FK_CONVENZIONE
                                        ) LOOP

                                            if j.DATAFINE > SYSDATE then
                                            gui.apriDiv(classe => 'left');
                                            gui.aggiungiIntestazione(testo => j.NOME, dimensione => 'h3');
                                            gui.chiudiDiv;
                                            gui.apriDiv(classe => 'right');
                                            gui.aggiungiIntestazione(testo => 'data di scadenza : ' || j.DATAFINE || '', dimensione => 'h3');
                                            gui.chiudiDiv;
                                            end if;
                                        END LOOP;
                                    END LOOP;

                                END IF;

                                gui.chiudiDiv; --flex-container
                            gui.chiudiGruppoInput;

                            gui.aCapo(2);

                                    if (SESSIONHANDLER.checkRuolo(idSess, 'Cliente')) then
                                        gui.aggiungiGruppoInput;
                                            gui.bottoneAggiungi (url => u_root || '.ModificaCliente?idSess='||idSess||'&cl_id='||SESSIONHANDLER.getIDUser(idSess)||'', testo => 'Modifica');
                                    gui.chiudiGruppoInput;

                                    gui.aCapo(2);

                                    gui.aggiungiGruppoInput;
                                            gui.bottoneAggiungi (url => u_root || '.associaConvenzione?idSess='||idSess||'', testo => 'Associa convenzione');
                                    gui.chiudiGruppoInput;

                                    gui.aCapo(2);

                                    end if;

                                    if (SESSIONHANDLER.checkRuolo (idSess, 'Manager')) then
                                    gui.aCapo(2);
                                        gui.aggiungiGruppoInput;
                                                gui.bottoneAggiungi (url => u_root || '.visualizzaClienti?idSess='||idSess||'', testo => 'Torna indietro');
                                        gui.chiudiGruppoInput;
                                    end if;


                    gui.chiudiForm;
                    gui.aCapo(3);
                gui.ChiudiPagina;

                END visualizzaProfilo;


    --visualizzazioneBustePaga : procedura che visualizza tutte le buste paga presenti nel database
    procedure visualizzaBustePaga(
        idSess in SESSIONIDIPENDENTI.IDSESSIONE%TYPE,
        r_FkDipendente in BUSTEPAGA.FK_DIPENDENTE%TYPE default null,
        r_FkContabile  in BUSTEPAGA.FK_CONTABILE%TYPE default null,
        r_Data       in varchar2 default null,
        r_Importo    in BUSTEPAGA.IMPORTO%TYPE default null,
        r_Bonus      in BUSTEPAGA.BONUS%TYPE default null,
        r_PopUp      in varchar2 default null
    ) is

            head gui.StringArray;

            BEGIN

        --QUESTO SERVE PER QUANDO SI REFRESHA LA PAGINA, IN MODO DA NON FAR RESTARE IL POP UP DELLA MODIFICA AVVENUTA CON SUCCESSO
        htp.prn('<script>   const newUrl = "'||U_ROOT||'.visualizzaBustePaga?idSess='||idSess||'";
                            history.replaceState(null, null, newUrl);
            </script>');


            head := gui.StringArray ('Dipendente', 'Data', 'Importo', 'Bonus', 'Contabile', ' ');
            gui.apriPagina(titolo => 'VisualizzazioneBustePaga', idSessione=> idSess);

            /* Controllo che l'utente abbia i permessi necessari */
            IF(sessionhandler.getRuolo(idSess) = 'Contabile') THEN
                IF (r_popUp = 'True') THEN
                    gui.AGGIUNGIPOPUP(True, 'Modifica avvenuta con successo!');
                END IF;

                gui.APRIFORMFILTRO();
                    gui.aggiungiinput(tipo=> 'hidden', nome => 'idSess', value=>idSess);
                    gui.aggiungicampoformfiltro(nome => 'r_FkDipendente', placeholder => 'Dipendente');
                    gui.aggiungicampoformfiltro(tipo => 'date', nome => 'r_Data', placeholder => 'Data');
                    gui.aggiungicampoformfiltro(nome => 'r_Importo', placeholder => 'Importo');
                    gui.aggiungicampoformfiltro(nome => 'r_Bonus', placeholder => 'Bonus');
                    gui.aggiungicampoformfiltro(nome => 'r_FkContabile', placeholder => 'Contabile');
                    gui.aggiungicampoformfiltro('submit', '','','Filtra');
                gui.CHIUDIFORMFILTRO;

                gui.aCapo;

                gui.APRITABELLA (elementi => head);

            for busta_paga IN (
                select *
                from bustepaga b
                where ( b.fk_dipendente = r_FkDipendente or r_FkDipendente is null )
                    and ( b.fk_contabile = r_FkContabile or r_FkContabile is null )
                    and ( trunc(b.DATA) = TO_DATE(r_Data, 'yyyy-mm-dd') or r_Data is null )
                    and ( b.importo = r_Importo or r_Importo is null )
                    and ( b.bonus = r_Bonus or r_Bonus is null )
                order by data desc

                /*
                select data, importo, bonus
                from bustepaga b
                where ( b.fk_dipendente = sessionhandler.getiduser(idSess) )
                    and ( trunc(b.data) = TO_DATE(r_Data, 'yyyy-mm-dd') or r_Data is null )
                    and ( b.importo = r_Importo or r_Importo is null )
                    and ( b.bonus = r_Bonus or r_Bonus is null )
                order by data desc)
                */
            )
            LOOP
                gui.AGGIUNGIRIGATABELLA;

                        gui.AGGIUNGIELEMENTOTABELLA(elemento => busta_paga.FK_DIPENDENTE);
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => busta_paga.Data);
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(busta_paga.IMPORTO, 'FM999G999G990D00', 'NLS_NUMERIC_CHARACTERS='',.'' NLS_CURRENCY=''€''')||'€');
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(busta_paga.BONUS, 'FM999G999G990D00', 'NLS_NUMERIC_CHARACTERS='',.'' NLS_CURRENCY=''€''')||'€');
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => busta_paga.FK_CONTABILE);

                    gui.apriElementoPulsanti;
                    gui.AGGIUNGIPULSANTEMODIFICA(collegamento => U_ROOT||'.modificaBustaPaga?idSess='||idSess||'&r_FkDipendente='||busta_paga.FK_DIPENDENTE||'&r_Data='||busta_paga.Data);
                    gui.chiudiElementoPulsanti;

                gui.CHIUDIRIGATABELLA;
            END LOOP;
                gui.ChiudiTabella;
            ELSE
                gui.AGGIUNGIPOPUP(FALSE, 'Errore: non hai i permessi necessari per accedere a questa pagina!', costanti.URL||'gui.homepage?idsessione'||idSess);
        END IF;

            gui.CHIUDIPAGINA();

        END visualizzaBustePaga;

        function existBustaPaga(
            r_FkDipendente in BUSTEPAGA.FK_DIPENDENTE%TYPE,
            r_Data in BUSTEPAGA.DATA%TYPE
        ) return boolean IS
            count_b NUMBER := 0;
        BEGIN
            SELECT COUNT(*) INTO count_b FROM BUSTEPAGA b WHERE b.FK_DIPENDENTE = r_FkDipendente AND TRUNC(b.Data) = TRUNC(r_Data);
            IF(count_b=1) THEN
                return TRUE;
            ELSE
                return FALSE;
            END IF;
        END existBustaPaga;

        procedure modificaBustaPaga (
            idSess in SESSIONIDIPENDENTI.IDSESSIONE%TYPE,
            r_FkDipendente in BUSTEPAGA.FK_CONTABILE%TYPE,
            r_Data in BUSTEPAGA.DATA%TYPE,
            r_PopUp in varchar2 default null,
            new_Importo in varchar2 default null,
            new_Data in varchar2 default null
        )
        IS
        -- Se la data della busta paga è maggiore della data odierna
        -- Modifica della data possibile soltanto per una data successiva a oggi
        bonus_percent number := 0;
        old_importo number := 0;
        old_contabile number :=0;
        head gui.StringArray;

        BEGIN

        --QUESTO SERVE PER QUANDO SI REFRESHA LA PAGINA, IN MODO DA NON FAR RESTARE I POP UP
        htp.prn('<script>   const newUrl = '||U_ROOT||'".modificaBustaPaga?idSess='||idSess||'&r_FkDipendente='||r_FkDipendente||'&r_Data='||r_Data||'";
                        history.replaceState(null, null, newUrl);
        </script>');

            gui.apriPagina(titolo => 'modificaBustaPaga', idSessione=>idSess);
            SAVEPOINT sp1;
            /* Controllo che l'utente sia un contabile e che la busta paga possa essere modificata */
            IF(SESSIONHANDLER.GETRUOLO(idSess) = 'Contabile' AND r_Data > TRUNC(SYSDATE) )THEN

                IF(r_PopUp IS NOT NULL) THEN
                    IF(r_PopUp = 'importoNegativo') THEN
                        gui.AGGIUNGIPOPUP(False, 'Errore: importo non può essere negativo. Modifica non effettuata!');
                    END IF;
                    IF(r_PopUp = 'dubBusta') THEN
                        gui.AGGIUNGIPOPUP(False, 'Errore: due buste paga nello stesso giorno. Modifica non effettuata!');
                    END IF;
                    IF(r_PopUp = 'noDataFound') THEN
                        gui.AGGIUNGIPOPUP(False, 'Errore: busta paga che si vuole modificare non esiste. Modifica non effettuata!');
                    END IF;
                END IF;

                gui.AGGIUNGIINTESTAZIONE(Testo => 'Modifica Busta Paga del dipendente '||r_FkDipendente, Dimensione=>'h1');

                -- Controllo che la busta paga esista
                IF(existBustaPaga (r_FkDipendente,  r_Data)) THEN
                    -- Recupero vecchio Importo e vecchio contabile
                    SELECT b.FK_CONTABILE, b.IMPORTO INTO old_contabile, old_importo
                    FROM BUSTEPAGA b
                    WHERE b.FK_DIPENDENTE = r_FkDipendente AND TRUNC(b.Data) = TRUNC(r_Data);
                    -- Creo il form
                    gui.AGGIUNGIFORM();
                        gui.AGGIUNGIINPUT(tipo=>'hidden', nome=>'idSess', value=>idSess);
                        gui.AGGIUNGIINPUT(tipo=>'hidden', nome=>'r_FkDipendente', value => r_FkDipendente);
                        gui.AGGIUNGIINPUT(tipo=>'hidden', nome=>'r_Data', value => r_Data);

                        gui.AGGIUNGIGRUPPOINPUT;
                            gui.AGGIUNGIINTESTAZIONE (testo => 'Importo', dimensione => 'h2');
                            gui.ACAPO;
                            gui.AGGIUNGIINTESTAZIONE (testo => 'Vecchio Importo: ', dimensione => 'h3');
                            gui.AGGIUNGIPARAGRAFO (testo => old_importo);
                            gui.ACAPO;
                            gui.AGGIUNGIINTESTAZIONE (testo => 'Nuovo Importo: ', dimensione => 'h3');
                            gui.AGGIUNGICAMPOFORM (classeIcona => 'fa fa-money-bill', nome => 'new_Importo', placeholder => 'Inserire nuovo importo...');
                        gui.CHIUDIGRUPPOINPUT;
                        gui.AGGIUNGIGRUPPOINPUT;
                            gui.AGGIUNGIINTESTAZIONE (testo => 'Data', dimensione => 'h2');
                            gui.ACAPO;
                            gui.AGGIUNGIINTESTAZIONE (testo => 'Vecchia Data: ', dimensione => 'h3');
                            gui.AGGIUNGIPARAGRAFO (testo => r_Data);
                            gui.ACAPO;
                            gui.AGGIUNGIINTESTAZIONE (testo => 'Nuova Data: ', dimensione => 'h3');
                            gui.AGGIUNGIINPUT(tipo=>'date', nome=>'new_Data', minimo=>''||TO_CHAR(SYSDATE,'yyyy-mm-dd')||'', massimo => ''||TO_CHAR(r_Data,'yyyy-mm-dd')||'');
                        gui.CHIUDIGRUPPOINPUT;

                        gui.AGGIUNGIGRUPPOINPUT;
                            gui.AGGIUNGIBOTTONESUBMIT (value => 'Modifica');
                        gui.CHIUDIGRUPPOINPUT;
                        gui.AGGIUNGIPARAGRAFO(Testo => 'Ultima modifica effettuata dal contabile: '||old_contabile);
                    gui.chiudiform;
                END IF;
                -- Recupero il bonus in percentuale da dipendenti
                SELECT d.BONUS INTO bonus_percent
                FROM DIPENDENTI d
                WHERE d.MATRICOLA = r_FkDipendente;

            IF (new_Importo > 0 AND bonus_percent >= 0) THEN
                -- Aggiornamento del contabile, dell'importo e del bonus (ricalcolato da dipendenti)
                UPDATE BUSTEPAGA
                SET BUSTEPAGA.FK_CONTABILE = SESSIONHANDLER.GETIDUSER(idSess),
                    BUSTEPAGA.DATA = TO_DATE(new_Data, 'yyyy-mm-dd'),
                    BUSTEPAGA.Importo = TO_NUMBER(new_Importo),
                    BUSTEPAGA.Bonus = (TO_NUMBER(new_Importo)*bonus_percent)/100
                WHERE BUSTEPAGA.Fk_Dipendente = r_FkDipendente AND BUSTEPAGA.Data = r_Data;
                -- Commit
                COMMIT;
                gui.REINDIRIZZA(U_ROOT||'.visualizzaBustePaga?idSess='||idSess||'&r_popUp=True');
            END IF;

        IF (new_Importo < 0) THEN
            gui.REINDIRIZZA(U_ROOT||'.modificaBustaPaga?idSess='||idSess||'&r_FkDipendente='||r_FkDipendente||'&r_Data='||r_Data||'&r_PopUp=importoNegativo');
        END IF;

        ELSE
            gui.AGGIUNGIPOPUP(False,'Errore: non hai i permessi necessari per accedere a questa pagina!', costanti.URL||'gui.homepage?idsessione'||idSess);
        END IF;

            gui.CHIUDIPAGINA();

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK  TO sp1;
            gui.REINDIRIZZA(U_ROOT||'.modificaBustaPaga?idSess='||idSess||'&r_FkDipendente='||r_FkDipendente||'&r_Data='||r_Data||'&r_popUp=noDataFound');
        WHEN DUP_VAL_ON_INDEX THEN
            ROLLBACK  TO sp1;
            gui.REINDIRIZZA(U_ROOT||'.modificaBustaPaga?idSess='||idSess||'&r_FkDipendente='||r_FkDipendente||'&r_Data='||r_Data||'&r_popUp=dubBusta');


        END modificaBustaPaga;

        procedure visualizzaBustePagaDipendente (
            idSess in SESSIONIDIPENDENTI.IDSESSIONE%TYPE,
            r_Data       in varchar2 default null,
            r_Importo    in BUSTEPAGA.IMPORTO%TYPE default null,
            r_Bonus      in BUSTEPAGA.BONUS%TYPE default null
        ) is

        head gui.StringArray;

        BEGIN

        gui.apriPagina (titolo => 'visualizza buste paga dipendenti', idSessione=>idSess);

        /* Controllo i permessi di accesso */
        IF(sessionhandler.getRuolo(idSess) = 'Autista' OR sessionhandler.getRuolo(idSess) = 'Operatore' OR sessionhandler.getRuolo(idSess) = 'Contabile' OR sessionhandler.getRuolo(idSess) = 'Manager') THEN

            gui.APRIFORMFILTRO();
                gui.AGGIUNGIINPUT(tipo => 'hidden', nome => 'idSess', value => idSess);
                gui.aggiungicampoformfiltro(tipo => 'date', nome => 'r_Data', placeholder => 'Data');
                gui.aggiungicampoformfiltro(nome => 'r_Importo', placeholder => 'Importo');
                gui.aggiungicampoformfiltro(nome => 'r_Bonus', placeholder => 'Bonus');
                gui.aggiungicampoformfiltro('submit', '', '','Filtra');
            gui.CHIUDIFORMFILTRO;

            gui.aCapo;

            head := gui.StringArray('Data', 'Importo', 'Bonus');
            gui.APRITABELLA (elementi => head);

            for busta_paga IN (
                select data, importo, bonus
                from bustepaga b
                where ( b.fk_dipendente = sessionhandler.getiduser(idSess) )
                    and ( trunc(b.data) = TO_DATE(r_Data, 'yyyy-mm-dd') or r_Data is null )
                    and ( b.importo = r_Importo or r_Importo is null )
                    and ( b.bonus = r_Bonus or r_Bonus is null )
                order by data desc)
            LOOP
                gui.AGGIUNGIRIGATABELLA;

                    gui.AGGIUNGIELEMENTOTABELLA(elemento => busta_paga.Data);
                    gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(busta_paga.IMPORTO, 'FM999G999G990D00', 'NLS_NUMERIC_CHARACTERS='',.'' NLS_CURRENCY=''€''')||'€');
                    gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(busta_paga.BONUS, 'FM999G999G990D00', 'NLS_NUMERIC_CHARACTERS='',.'' NLS_CURRENCY=''€''')||'€');

                gui.ChiudiRigaTabella;
                end LOOP;

            gui.ChiudiTabella;
    ELSE
        gui.AGGIUNGIPOPUP(False, 'Errore: non hai i permessi necessari per accedere alla pagina', costanti.URL||'gui.homepage?idsessione'||idSess);
    END IF;

        gui.CHIUDIPAGINA();

        END visualizzaBustePagaDipendente;


        function existDipendente(r_IdDipendente in DIPENDENTI.MATRICOLA%TYPE) return number IS
            count_d NUMBER;
        BEGIN
            SELECT COUNT(*) INTO count_d FROM DIPENDENTI d WHERE d.Matricola = r_IdDipendente;
            IF(count_d=0) THEN
                return 0;
            ELSE IF(count_d = 1) THEN
                    return 1;
                ELSE
                    return 2;
                END IF;
            END IF;
        END existDipendente;

        procedure inserimentoBustaPaga(
            idSess in SESSIONIDIPENDENTI.IDSESSIONE%TYPE,
            r_FkDipendente in BUSTEPAGA.FK_DIPENDENTE%TYPE default null,
            r_Data       in varchar2 default null,
            r_Importo    in BUSTEPAGA.IMPORTO%TYPE default null,
            r_PopUp     in varchar2 default null
        ) IS

        bonus_percent NUMBER := 0;

        head gui.StringArray;

        dup_Val_Dipendenti EXCEPTION;

        BEGIN

            --QUESTO SERVE PER QUANDO SI REFRESHA LA PAGINA, IN MODO DA NON FAR RESTARE I POP UP
            htp.prn('<script>   const newUrl = "'||U_ROOT||'.inserimentoBustaPaga?idSess='||idSess||'";
                            history.replaceState(null, null, newUrl);
            </script>');

            SAVEPOINT sp1;

            --Controllo i permessi di accesso
            IF(sessionhandler.getRuolo(idSess) = 'Contabile') THEN

                gui.APRIPAGINA(titolo => 'inserimentoBustaPaga', idSessione => idSess);

                IF(r_PopUp = 'importoNegativo') THEN
                    gui.AGGIUNGIPOPUP(False, 'Errore: Non è possibile inserire un importo negativo. Inserimento busta paga non effettuato.');
                END if;
                -- noDataFound Exception
                IF (r_PopUp = 'NoDataFound') THEN
                    gui.AGGIUNGIPOPUP(False, 'Errore: Non esiste un dipendente con la matricola inserita. Inserimento busta paga non effettuato.');
                END IF;
                -- tooManyRows Exception
                IF (r_PopUp = 'dupVal') THEN
                    gui.AGGIUNGIPOPUP(False, 'Errore: Esistono più buste paga per quel dipendente alla solita data. Inserimento busta paga non effettuato.');
                END IF;

                IF (r_PopUp = 'True') THEN
                    gui.AggiungiPopup(True, 'Busta paga inserita con successo!');
                END IF;

            gui.AGGIUNGIFORM (url => U_ROOT||'.inserimentoBustaPaga');

                    gui.aggiungiIntestazione(testo => 'Inserimento Busta Paga', dimensione => 'h2');
                    gui.ACAPO();
                    gui.AGGIUNGIGRUPPOINPUT;
                        gui.AGGIUNGIINPUT(tipo=>'hidden', nome=>'idSess', value => idSess);
                        gui.AGGIUNGICAMPOFORM (classeIcona => 'fa fa-user', nome => 'r_FkDipendente', placeholder => 'Identificativo Dipendente');
                        gui.AGGIUNGICAMPOFORM (classeIcona => 'fa fa-money-bill', nome => 'r_Importo', placeholder => 'Importo');
                        gui.aggiungiinput(tipo=>'date', nome=>'r_Data');
                    gui.CHIUDIGRUPPOINPUT;

                    gui.AGGIUNGIGRUPPOINPUT;
                            gui.aggiungiBottoneSubmit (value => 'Inserisci');
                    gui.CHIUDIGRUPPOINPUT;

            gui.CHIUDIFORM;
            IF(r_Importo IS NOT NULL) THEN
                IF ( r_Importo > 0 ) THEN
                    -- Controllo che esista il dipendente.
                    IF(existDipendente(r_FkDipendente) = 1) THEN
                        SELECT d.Bonus INTO bonus_percent FROM DIPENDENTI d WHERE d.Matricola = sessionhandler.getiduser(idSess);
                        INSERT INTO BUSTEPAGA (FK_Dipendente, FK_Contabile, Data, Importo, Bonus) VALUES
                        (r_FkDipendente, sessionhandler.getiduser(idSess), TO_DATE(r_Data,'yyyy-mm-dd'), r_Importo, ((r_Importo*bonus_percent)/100));
                        --Commit
                        COMMIT;
                        gui.REINDIRIZZA(u_root||'.inserimentoBustaPaga?idSess='||idSess||'&r_popUp=True');
                    ELSE IF( existDipendente(r_FkDipendente) = 0 ) THEN
                            RAISE NO_DATA_FOUND;
                        ELSE
                            RAISE dup_Val_Dipendenti;
                        END IF;
                    END IF;
                ELSE
                    gui.REINDIRIZZA(u_root||'.inserimentoBustaPaga?idSess='||idSess||'&r_popUp=importoNegativo');
                END IF;
            END IF;
        ELSE
            gui.AGGIUNGIPOPUP(False, 'Errore: non hai i permessi necessari per accedere alla pagina!', costanti.URL||'gui.homepage?idsessione'||idSess);
        END IF;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK TO sp1;
            gui.REINDIRIZZA(u_root||'.inserimentoBustaPaga?idSess='||idSess||'&r_popUp=NoDataFound');
        -- C'è già una busta paga per quel dipendente in quel giorno
        WHEN DUP_VAL_ON_INDEX THEN
            ROLLBACK TO sp1;
            gui.REINDIRIZZA(u_root||'.inserimentoBustaPaga?idSess='||idSess||'&r_popUp=dupVal');
        WHEN OTHERS THEN
            IF(SQLCODE = -1) THEN
                -- unique costraint violated
                gui.REINDIRIZZA(u_root||'.inserimentoBustaPaga?idSess='||idSess||'&r_popUp=dupVal');
            END IF;

        END inserimentoBustaPaga;

        procedure visualizzaRicaricheCliente (
            idSess in SESSIONICLIENTI.IDSESSIONE%TYPE,
            r_Data       in varchar2 default null,
            r_Importo    in RICARICHE.IMPORTO%TYPE default null,
            r_PopUp in varchar2 default null
        ) is

        head gui.stringArray;

        BEGIN

    --QUESTO SERVE PER QUANDO SI REFRESHA LA PAGINA, IN MODO DA NON FAR RESTARE I POP UP
        htp.prn('<script>   const newUrl = "'||U_ROOT||'.visualizzaRicaricheCliente?idSess='||idSess||'";
                        history.replaceState(null, null, newUrl);
        </script>');

        gui.apriPagina (titolo => 'Visualizzazione Ricariche cliente', idSessione=>idSess);

        IF(r_PopUp IS NOT NULL) THEN
            IF(r_PopUp = 'True') THEN
                gui.AGGIUNGIPOPUP(True, 'Ricarica inserita con successo!');
            ELSE
                gui.AGGIUNGIPOPUP(False, 'Ricarica non inserita!');
            END IF;
        END IF;


        /* Controllo i permessi di accesso */
        IF(sessionhandler.getruolo(idSess) = 'Cliente') THEN

            gui.APRIFORMFILTRO();
                gui.AGGIUNGIINPUT(tipo => 'hidden', nome => 'idSess', value => idSess);
                gui.aggiungicampoformfiltro(nome => 'r_Importo', placeholder => 'Importo');
                    gui.aggiungicampoformfiltro(tipo => 'date', nome => 'r_Data', placeholder => 'Data');
                    gui.aggiungicampoformfiltro('submit', '', '', 'Filtra');
                gui.ACAPO;
            gui.CHIUDIFORMFILTRO;

            head := gui.StringArray('Identificativo','Importo', 'Data');
            gui.APRITABELLA (elementi => head);

            for ricarica IN (
                    select idricarica, importo,data
                    from ricariche r
                    where ( r.fk_cliente = sessionhandler.getiduser(idSess) )
                        and ( trunc(r.data) = TO_DATE(r_Data,'yyyy-mm-dd')  or r_Data is null )
                        and ( r.importo = r_Importo or r_Importo is null )
                    order by data desc
                )
            LOOP
                gui.AGGIUNGIRIGATABELLA;
                    gui.aggiungielementotabella(elemento => ricarica.idricarica);
                    gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(ricarica.IMPORTO, 'FM999G999G990D00', 'NLS_NUMERIC_CHARACTERS='',.'' NLS_CURRENCY=''€''')||'€');
                    gui.AGGIUNGIELEMENTOTABELLA(elemento => ricarica.Data);
                gui.ChiudiRigaTabella;
            end LOOP;

            gui.ChiudiTabella;
            gui.BOTTONEAGGIUNGI(testo=>'Inserisci Ricarica', classe=>'bottone2', url=> U_ROOT||'.inserimentoRicarica?idSess='||idSess);
    ELSE
        gui.AggiungiPopup(False, 'Errore: non hai il permesso per accedere a questa pagina', costanti.URL||'gui.homepage?idsessione'||idSess);
    END IF;
    END visualizzaRicaricheCliente;

    procedure inserimentoRicarica (
        idSess in SESSIONICLIENTI.IDSESSIONE%TYPE,
        r_Importo    in RICARICHE.IMPORTO%TYPE default null,
        r_PopUp in varchar2 default null
    )IS

        head gui.StringArray;

        ImportoNegativo EXCEPTION;

    BEGIN
        --QUESTO SERVE PER QUANDO SI REFRESHA LA PAGINA, IN MODO DA NON FAR RESTARE I POP UP
        htp.prn('<script>   const newUrl = "'||U_ROOT||'.inserimentoRicarica?idSess='||idSess||'";
                        history.replaceState(null, null, newUrl);
        </script>');

        gui.APRIPAGINA(titolo => 'inserimentoRicarica', idSessione=>idSess);

        IF(r_PopUp IS NOT NULL AND r_PopUp = 'False') THEN
                gui.AGGIUNGIPOPUP(False, 'Ricarica non inserita!');
        END IF;

        IF(r_PopUp = 'ImportoNegativo') THEN
            gui.AGGIUNGIPOPUP(False, 'Errore: Importo inserito non positivo. Ricarica non inserita.');
        END IF;

        SAVEPOINT sp1;

        /* Controllo i permessi di accesso */
        IF(sessionhandler.getruolo(idSess) = 'Cliente' ) THEN
            gui.AGGIUNGIFORM (url => U_ROOT||'.inserimentoRicarica');
                gui.aggiungiIntestazione(testo => 'Inserimento Ricarica', dimensione => 'h2');
                gui.AGGIUNGIGRUPPOINPUT;
                    gui.AGGIUNGIINPUT(tipo => 'hidden', nome => 'idSess', value => idSess);
                    gui.AGGIUNGICAMPOFORM (classeIcona => 'fa fa-money-bill', nome => 'r_Importo', placeholder => 'Importo');
                gui.CHIUDIGRUPPOINPUT;

                    gui.AGGIUNGIGRUPPOINPUT;
                        gui.AGGIUNGIBOTTONESUBMIT (value => 'Inserisci');
                    gui.CHIUDIGRUPPOINPUT;
            gui.CHIUDIFORM;

            IF(r_importo IS NOT NULL) THEN
                /* Inserimento nuova ricarica */
                INSERT INTO RICARICHE VALUES(seq_IDricarica.NEXTVAL, sessionhandler.getiduser(idSess), SYSDATE, r_Importo);
                /* Aggiornamento del Saldo */
                UPDATE CLIENTI SET Saldo = (SELECT c.Saldo FROM CLIENTI c WHERE c.IDCLIENTE = sessionhandler.getiduser(idSess)) + r_Importo
                WHERE IDcliente = sessionhandler.getiduser(idSess);
                COMMIT;
                /* Reindiriziamo alla pagina visualizzaRicaricheCliente */
                gui.REINDIRIZZA(U_ROOT||'.visualizzaRicaricheCliente?idSess='||idSess||'&r_PopUp=True');
            END IF;
        ELSE
            gui.AggiungiPopup(False, 'Errore: non hai i permessi per accedere a questa pagina!', costanti.URL||'gui.homepage?idsessione'||idSess);
        END IF;

        EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20051 THEN
                -- vincolo check importo>0 violato
                ROLLBACK TO sp1;
                gui.REINDIRIZZA(U_ROOT||'.inserimentoRicarica?idSess='||idSess||'&r_PopUp=ImportoNegativo');
            END IF;

    end inserimentoRicarica;

    function bustePagaIsEmpty return BOOLEAN IS
        count_b NUMBER := 0;
    BEGIN
        SELECT COUNT(*) INTO count_b FROM BUSTEPAGA b;
        IF (count_b = 0) THEN
            return TRUE;
        ELSE
            return FALSE;
        END IF;
    end bustePagaIsEmpty;

procedure dettagliStipendiPersonale(
    idSess in SESSIONIDIPENDENTI.IDSESSIONE%TYPE,
    r_DataInizio in varchar2 default null,
    r_DataFine in varchar2 default null
)
IS
    totStipAutisti number :=0;
    totStipOperatori number :=0;
    totStipContabili number :=0;
    totStipManager number := 0;
    totStipGeneral number := 0;
    minDate varchar2(20);
    maxDate varchar2(20);
    head gui.stringArray;
BEGIN
    IF(sessionhandler.GETRUOLO(idSess) = 'Manager') THEN
        gui.APRIPAGINA(titolo=> 'dettagliStipendiPersonale', idSessione=>idSess);
        -- controllo che la tabella non sia vuota
        IF(NOT bustePagaIsEmpty()) THEN
            -- Recupero data minima e massima in buste paga
            SELECT TO_CHAR(MIN(b.DATA), 'dd/mm/yyyy') INTO minDate
            FROM BUSTEPAGA b;
            SELECT TO_CHAR(MAX(b.DATA), 'dd/mm/yyyy') INTO maxDate
            FROM BUSTEPAGA b;
            -- Recupero somma stipendi di tutti
            SELECT SUM(b.IMPORTO + b.BONUS) INTO totStipGeneral
            FROM (DIPENDENTI d JOIN BUSTEPAGA b ON (d.MATRICOLA = b.FK_DIPENDENTE))
            WHERE ( b.data >= TO_DATE(r_DataInizio,'yyyy-mm-dd')  or r_DataInizio is null )
              AND ( b.data <= TO_DATE(r_DataFine,'yyyy-mm-dd')  or r_DataFine is null );
            -- Recupero somma stipendi autisti
            SELECT SUM(b.IMPORTO + b.BONUS) INTO totStipAutisti
            FROM (AUTISTI a JOIN DIPENDENTI d ON (a.FK_DIPENDENTE = d.MATRICOLA) JOIN BUSTEPAGA b ON (d.MATRICOLA = b.FK_DIPENDENTE))
            WHERE ( b.data >= TO_DATE(r_DataInizio,'yyyy-mm-dd')  or r_DataInizio is null )
              AND ( b.data <= TO_DATE(r_DataFine,'yyyy-mm-dd')  or r_DataFine is null );
            -- Recupero somma stipendi operatori
            SELECT SUM(b.IMPORTO + b.BONUS) INTO totStipOperatori
            FROM (OPERATORI o JOIN DIPENDENTI d ON (o.FK_DIPENDENTE = d.MATRICOLA) JOIN BUSTEPAGA b ON (d.MATRICOLA = b.FK_DIPENDENTE))
            WHERE ( b.data >= TO_DATE(r_DataInizio,'yyyy-mm-dd')  or r_DataInizio is null )
              AND ( b.data <= TO_DATE(r_DataFine,'yyyy-mm-dd')  or r_DataFine is null );
            -- Recupero somma stipendi contabili
            SELECT SUM(b.IMPORTO + b.BONUS) INTO totStipContabili
            FROM (RESPONSABILI r JOIN DIPENDENTI d ON (r.FK_DIPENDENTE = d.MATRICOLA) JOIN BUSTEPAGA b ON (d.MATRICOLA = b.FK_DIPENDENTE))
            WHERE r.RUOLO = 1 AND ( b.data >= TO_DATE(r_DataInizio,'yyyy-mm-dd')  or r_DataInizio is null )
              AND ( b.data <= TO_DATE(r_DataFine,'yyyy-mm-dd')  or r_DataFine is null );
            -- Recupero somma stipendi manager
            SELECT SUM(b.IMPORTO + b.BONUS) INTO totStipManager
            FROM (RESPONSABILI r JOIN DIPENDENTI d ON (r.FK_DIPENDENTE = d.MATRICOLA) JOIN BUSTEPAGA b ON (d.MATRICOLA = b.FK_DIPENDENTE))
            WHERE r.RUOLO = 0 AND ( b.data >= TO_DATE(r_DataInizio,'yyyy-mm-dd')  or r_DataInizio is null )
              AND ( b.data <= TO_DATE(r_DataFine,'yyyy-mm-dd')  or r_DataFine is null );
            -- Controllo valori restituiti
            IF(totStipAutisti IS NULL) THEN
                totStipAutisti := 0;
            end if;
            IF(totStipOperatori IS NULL) THEN
                totStipOperatori := 0;
            end if;
            IF(totStipContabili IS NULL) THEN
                totStipContabili := 0;
            end if;
            IF(totStipManager IS NULL) THEN
                totStipManager := 0;
            end if;
            IF(totStipGeneral IS NULL) THEN
                totStipGeneral := 0;
            end if;
            -- interfaccia
            gui.AGGIUNGIFORM();
            gui.AGGIUNGIINTESTAZIONE (testo => 'Dettagli Stipendi Personale', dimensione => 'h1');
            gui.APRIFORMFILTRO();
                gui.AGGIUNGIINPUT(tipo => 'hidden', nome => 'idSess', value => idSess);
                    gui.aggiungicampoformfiltro(tipo => 'date', nome => 'r_DataInizio', placeholder => 'Data Inizio');
                    gui.aggiungicampoformfiltro(tipo => 'date', nome => 'r_DataFine', placeholder => 'Data Fine');
                    gui.aggiungicampoformfiltro('submit', '', '', 'Filtra');
                gui.ACAPO;
            gui.CHIUDIFORMFILTRO;
            gui.AGGIUNGIGRUPPOINPUT;
                gui.AGGIUNGIINTESTAZIONE (testo => 'Personale completo', dimensione => 'h2');
                gui.AGGIUNGIINTESTAZIONE (testo => 'Totale Stipendi: ', dimensione => 'h3');
                gui.AGGIUNGIPARAGRAFO (testo => TO_CHAR(totStipGeneral, 'FM999G999G990D00', 'NLS_NUMERIC_CHARACTERS='',.'' NLS_CURRENCY=''€''')||'€');
                gui.AGGIUNGIINTESTAZIONE (testo => 'Autisti', dimensione => 'h2');
                gui.AGGIUNGIINTESTAZIONE (testo => 'Totale Stipendi: ', dimensione => 'h3');
                gui.AGGIUNGIPARAGRAFO (testo => TO_CHAR(totStipAutisti, 'FM999G999G990D00', 'NLS_NUMERIC_CHARACTERS='',.'' NLS_CURRENCY=''€''')||'€');
                IF(r_DataInizio IS NOT NULL AND r_DataFine IS NOT NULL) THEN
                    gui.AGGIUNGIINTESTAZIONE (testo => 'Top 3 autisti più pagati (' ||TO_CHAR(TO_DATE(r_DataInizio, 'yyyy-mm-dd'), 'dd/mm/yyyy')||' - '||TO_CHAR(TO_DATE(r_DataFine, 'yyyy-mm-dd'), 'dd/mm/yyyy')||'): ', dimensione => 'h3');
                ELSE
                    gui.AGGIUNGIINTESTAZIONE (testo => 'Top 3 autisti più pagati (' ||minDate||' - '||maxDate||'): ', dimensione => 'h3');
                END IF;
                head := gui.StringArray('Identificativo','Euro netti percepiti');
                gui.APRITABELLA (elementi => head);
                for autista IN (
                        SELECT *
                        FROM (SELECT d.MATRICOLA, SUM(b.IMPORTO + b.BONUS) AS stipTot
                              FROM (AUTISTI a JOIN DIPENDENTI d ON (a.FK_DIPENDENTE = d.MATRICOLA) JOIN BUSTEPAGA b
                                    ON (d.MATRICOLA = b.FK_DIPENDENTE))
                              WHERE (b.data >= TO_DATE(r_DataInizio, 'yyyy-mm-dd') or r_DataInizio is null)
                                AND (b.data <= TO_DATE(r_DataFine, 'yyyy-mm-dd') or r_DataFine is null)
                              GROUP BY d.MATRICOLA
                              ORDER BY stipTot DESC )
                        WHERE ROWNUM <=3
                    )
                LOOP
                    gui.AGGIUNGIRIGATABELLA;
                        gui.aggiungielementotabella(elemento => autista.MATRICOLA);
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(autista.stipTot, 'FM999G999G990D00', 'NLS_NUMERIC_CHARACTERS='',.'' NLS_CURRENCY=''€''')||'€');
                    gui.ChiudiRigaTabella;
                end LOOP;
                gui.CHIUDITABELLA();
                gui.ACAPO();
                gui.AGGIUNGIINTESTAZIONE (testo => 'Operatori', dimensione => 'h2');
                gui.AGGIUNGIINTESTAZIONE (testo => 'Totale Stipendi: ', dimensione => 'h3');
                gui.AGGIUNGIPARAGRAFO (testo => TO_CHAR(totStipOperatori, 'FM999G999G990D00', 'NLS_NUMERIC_CHARACTERS='',.'' NLS_CURRENCY=''€''')||'€');
                IF(r_DataInizio IS NOT NULL AND r_DataFine IS NOT NULL) THEN
                    gui.AGGIUNGIINTESTAZIONE (testo => 'Top 3 operatori più pagati (' ||TO_CHAR(TO_DATE(r_DataInizio, 'yyyy-mm-dd'), 'dd/mm/yyyy')||' - '||TO_CHAR(TO_DATE(r_DataFine, 'yyyy-mm-dd'), 'dd/mm/yyyy')||'): ', dimensione => 'h3');
                ELSE
                    gui.AGGIUNGIINTESTAZIONE (testo => 'Top 3 operatori più pagati (' ||minDate||' - '||maxDate||'): ', dimensione => 'h3');
                END IF;
                head := gui.StringArray('Identificativo','Euro netti percepiti');
                gui.APRITABELLA (elementi => head);
                for operatore IN (
                        SELECT *
                        FROM (SELECT d.MATRICOLA, SUM(b.IMPORTO + b.BONUS) AS stipTot
                              FROM (Operatori o JOIN DIPENDENTI d ON (o.FK_DIPENDENTE = d.MATRICOLA) JOIN BUSTEPAGA b
                                    ON (d.MATRICOLA = b.FK_DIPENDENTE))
                              WHERE (b.data >= TO_DATE(r_DataInizio, 'yyyy-mm-dd') or r_DataInizio is null)
                                AND (b.data <= TO_DATE(r_DataFine, 'yyyy-mm-dd') or r_DataFine is null)
                              GROUP BY d.MATRICOLA
                              ORDER BY stipTot DESC )
                        WHERE ROWNUM <=3
                    )
                LOOP
                    gui.AGGIUNGIRIGATABELLA;
                        gui.aggiungielementotabella(elemento => operatore.MATRICOLA);
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(operatore.stipTot, 'FM999G999G990D00', 'NLS_NUMERIC_CHARACTERS='',.'' NLS_CURRENCY=''€''')||'€');
                    gui.ChiudiRigaTabella;
                end LOOP;
                gui.CHIUDITABELLA();
                gui.ACAPO;
                gui.AGGIUNGIINTESTAZIONE (testo => 'Contabili', dimensione => 'h2');
                gui.AGGIUNGIINTESTAZIONE (testo => 'Totale Stipendi: ', dimensione => 'h3');
                gui.AGGIUNGIPARAGRAFO (testo => TO_CHAR(totStipContabili, 'FM999G999G990D00', 'NLS_NUMERIC_CHARACTERS='',.'' NLS_CURRENCY=''€''')||'€');
                IF(r_DataInizio IS NOT NULL AND r_DataFine IS NOT NULL) THEN
                    gui.AGGIUNGIINTESTAZIONE (testo => 'Top 3 contabili più pagati (' ||TO_CHAR(TO_DATE(r_DataInizio, 'yyyy-mm-dd'), 'dd/mm/yyyy')||' - '||TO_CHAR(TO_DATE(r_DataFine, 'yyyy-mm-dd'), 'dd/mm/yyyy')||'): ', dimensione => 'h3');
                ELSE
                    gui.AGGIUNGIINTESTAZIONE (testo => 'Top 3 contabili più pagati (' ||minDate||' - '||maxDate||'): ', dimensione => 'h3');
                END IF;
                head := gui.StringArray('Identificativo','Euro netti percepiti');
                gui.APRITABELLA (elementi => head);
                for contabile IN (
                        SELECT *
                        FROM (SELECT d.MATRICOLA, SUM(b.IMPORTO + b.BONUS) AS stipTot
                              FROM (Responsabili r JOIN DIPENDENTI d ON (r.FK_DIPENDENTE = d.MATRICOLA) JOIN BUSTEPAGA b
                                    ON (d.MATRICOLA = b.FK_DIPENDENTE))
                              WHERE r.RUOLO = 1
                                AND (b.data >= TO_DATE(r_DataInizio, 'yyyy-mm-dd') or r_DataInizio is null)
                                AND (b.data <= TO_DATE(r_DataFine, 'yyyy-mm-dd') or r_DataFine is null)
                              GROUP BY d.MATRICOLA
                              ORDER BY stipTot DESC )
                        WHERE ROWNUM <=3
                    )
                LOOP
                    gui.AGGIUNGIRIGATABELLA;
                        gui.aggiungielementotabella(elemento => contabile.MATRICOLA);
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(contabile.stipTot, 'FM999G999G990D00', 'NLS_NUMERIC_CHARACTERS='',.'' NLS_CURRENCY=''€''')||'€');
                    gui.ChiudiRigaTabella;
                end LOOP;
                gui.CHIUDITABELLA();
                gui.ACAPO;
                gui.AGGIUNGIINTESTAZIONE (testo => 'Manager', dimensione => 'h2');
                gui.AGGIUNGIINTESTAZIONE (testo => 'Totale Stipendi: ', dimensione => 'h3');
                gui.AGGIUNGIPARAGRAFO (testo => TO_CHAR(totStipManager, 'FM999G999G990D00', 'NLS_NUMERIC_CHARACTERS='',.'' NLS_CURRENCY=''€''')||'€');
                IF(r_DataInizio IS NOT NULL AND r_DataFine IS NOT NULL) THEN
                    gui.AGGIUNGIINTESTAZIONE (testo => 'Top 3 manager più pagati (' ||TO_CHAR(TO_DATE(r_DataInizio, 'yyyy-mm-dd'), 'dd/mm/yyyy')||' - '||TO_CHAR(TO_DATE(r_DataFine, 'yyyy-mm-dd'), 'dd/mm/yyyy')||'): ', dimensione => 'h3');
                ELSE
                    gui.AGGIUNGIINTESTAZIONE (testo => 'Top 3 manager più pagati (' ||minDate||' - '||maxDate||'): ', dimensione => 'h3');
                END IF;
                head := gui.StringArray('Identificativo','Euro netti percepiti');
                gui.APRITABELLA (elementi => head);
                for manager IN (
                        SELECT *
                        FROM (SELECT d.MATRICOLA, SUM(b.IMPORTO + b.BONUS) AS stipTot
                              FROM (Responsabili r JOIN DIPENDENTI d ON (r.FK_DIPENDENTE = d.MATRICOLA) JOIN BUSTEPAGA b
                                    ON (d.MATRICOLA = b.FK_DIPENDENTE))
                              WHERE r.RUOLO = 0
                                AND (b.data >= TO_DATE(r_DataInizio, 'yyyy-mm-dd') or r_DataInizio is null)
                                AND (b.data <= TO_DATE(r_DataFine, 'yyyy-mm-dd') or r_DataFine is null)
                              GROUP BY d.MATRICOLA
                              ORDER BY stipTot DESC )
                        WHERE ROWNUM <=3
                    )
                LOOP
                    gui.AGGIUNGIRIGATABELLA;
                        gui.aggiungielementotabella(elemento => manager.MATRICOLA);
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(manager.stipTot, 'FM999G999G990D00', 'NLS_NUMERIC_CHARACTERS='',.'' NLS_CURRENCY=''€''')||'€');
                    gui.ChiudiRigaTabella;
                end LOOP;
                gui.CHIUDITABELLA();
                gui.CHIUDIGRUPPOINPUT;
            gui.CHIUDIFORM();

                gui.CHIUDIPAGINA();
            ELSE
                RAISE NO_DATA_FOUND;
            END IF;
        ELSE
            gui.AGGIUNGIPOPUP(False, 'Errore: non hai i permessi per accedere a questa pagina', costanti.URL||'gui.homepage?idsessione'||idSess);
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            gui.AGGIUNGIPOPUP(False,'Errore: nessun dato presente.');
    END dettagliStipendiPersonale;

    function ricaricheIsEmpty return BOOLEAN IS
        count_r NUMBER := 0;
    BEGIN
        SELECT COUNT(*) INTO count_r FROM RICARICHE r;
        IF (count_r = 0) THEN
            return TRUE;
        ELSE
            return FALSE;
        END IF;
    end ricaricheIsEmpty;

        procedure dettagliRicaricheClienti(
            idSess in SESSIONIDIPENDENTI.IDSESSIONE%TYPE,
            r_DataInizio in varchar2 default null,
            r_DataFine in varchar2 default null
        ) IS

            minDate varchar2(10);
            maxDate varchar2(10);
            totRicariche number := 0;
            totRicaricheDataInizio number := 0;
            totRicaricheDataFine number := 0;
            trendPercent number := 0;
            delta number := 0;
            head gui.stringArray;

BEGIN
    gui.APRIPAGINA(titolo=> 'dettagliRicaricheClienti', idSessione=>idSess);
    IF(sessionhandler.GETRUOLO(idSess) = 'Manager') THEN
        -- controllo che la tabella ricariche non sia vuota
        IF(NOT ricaricheIsEmpty()) THEN
            -- Recupero data minima e massima in ricariche.
            SELECT TO_CHAR(MIN(r.DATA), 'yyyy-mm-dd') INTO minDate
            FROM RICARICHE r;
            SELECT TO_CHAR(MAX(r.DATA), 'yyyy-mm-dd') INTO maxDate
            FROM RICARICHE r;
            -- Recupero il totale delle ricariche.
            SELECT SUM(r.IMPORTO) INTO totRicariche
            FROM RICARICHE r
            WHERE (r.data >= TO_DATE(r_DataInizio, 'yyyy-mm-dd') or r_DataInizio is null)
                AND ((r.data <= (TO_DATE(r_DataFine, 'yyyy-mm-dd') +1)) or r_DataFine is null);
            -- totRicaricheDataInizio e totRicaricheDataFine
            IF(r_DataInizio IS NOT NULL AND r_DataFine IS NOT NULL) THEN
                SELECT SUM(r.IMPORTO) INTO totRicaricheDataInizio
                FROM RICARICHE r
                WHERE (trunc(r.data) = TO_DATE(r_DataInizio, 'yyyy-mm-dd'));
                SELECT SUM(r.IMPORTO) INTO totRicaricheDataFine
                FROM RICARICHE r
                WHERE (trunc(r.data) = TO_DATE(r_DataFine, 'yyyy-mm-dd'));
            ELSE
                SELECT SUM(r.IMPORTO) INTO totRicaricheDataInizio
                FROM RICARICHE r
                WHERE (trunc(r.data) = TO_DATE(minDate, 'yyyy-mm-dd'));
                SELECT SUM(r.IMPORTO) INTO totRicaricheDataFine
                FROM RICARICHE r
                WHERE (trunc(r.data) = TO_DATE(maxDate, 'yyyy-mm-dd'));
            END IF;
            -- Controlli sui valori restituiti
            IF(totRicaricheDataInizio IS NULL) THEN
                totRicaricheDataInizio:=1;
            END IF;
            IF(totRicaricheDataFine IS NULL) THEN
                totRicaricheDataFine:=1;
            END IF;
            IF(totRicariche IS NULL) THEN
                totRicariche:=0;
            END IF;
            -- Trend
            delta :=  totRicaricheDataFine - totRicaricheDataInizio;
            trendPercent := ((delta * 100) /totRicaricheDataInizio);
            -- gui
            gui.AGGIUNGIFORM();
                gui.AGGIUNGIINTESTAZIONE (testo => 'Dettagli Ricariche Clienti', dimensione => 'h1');
                gui.APRIFORMFILTRO();
                    gui.AGGIUNGIINPUT(tipo => 'hidden', nome => 'idSess', value => idSess);
                        gui.aggiungicampoformfiltro(tipo => 'date', nome => 'r_DataInizio', placeholder => 'Data Inizio');
                        gui.aggiungicampoformfiltro(tipo => 'date', nome => 'r_DataFine', placeholder => 'Data Fine');
                        gui.aggiungicampoformfiltro('submit', '', '', 'Filtra');
                    gui.ACAPO;
                gui.CHIUDIFORMFILTRO;
                gui.AGGIUNGIGRUPPOINPUT;
                    gui.AGGIUNGIINTESTAZIONE (testo => 'Incasso Ricariche', dimensione => 'h2');
                    IF(r_DataInizio IS NOT NULL AND r_DataFine IS NOT NULL) THEN
                        gui.AGGIUNGIINTESTAZIONE (testo => 'Totale tra le date (' ||TO_CHAR(TO_DATE(r_DataInizio, 'yyyy-mm-dd'), 'dd/mm/yyyy')||' - '||TO_CHAR(TO_DATE(r_DataFine, 'yyyy-mm-dd'), 'dd/mm/yyyy')||'): ', dimensione => 'h3');
                    ELSE
                        gui.AGGIUNGIINTESTAZIONE (testo => 'Totale tra le date (' ||TO_CHAR(TO_DATE(minDate, 'yyyy-mm-dd'), 'dd/mm/yyyy')||' - '||TO_CHAR(TO_DATE(maxDate, 'yyyy-mm-dd'), 'dd/mm/yyyy')||'): ', dimensione => 'h3');
                    END IF;
                    gui.AGGIUNGIPARAGRAFO (testo => TO_CHAR(totRicariche, 'FM999G999G990D00', 'NLS_NUMERIC_CHARACTERS='',.'' NLS_CURRENCY=''€''')||'€');
                    gui.AGGIUNGIINTESTAZIONE (testo => 'Trend percentuale', dimensione => 'h2');
                    IF(r_DataInizio IS NOT NULL AND r_DataFine IS NOT NULL) THEN
                        gui.AGGIUNGIINTESTAZIONE (testo => 'Totale (' ||TO_CHAR(TO_DATE(r_DataInizio, 'yyyy-mm-dd'), 'dd/mm/yyyy')||' - '||TO_CHAR(TO_DATE(r_DataFine, 'yyyy-mm-dd'), 'dd/mm/yyyy')||'): ', dimensione => 'h3');
                    ELSE
                        gui.AGGIUNGIINTESTAZIONE (testo => 'Totale (' ||TO_CHAR(TO_DATE(minDate, 'yyyy-mm-dd'), 'dd/mm/yyyy')||' - '||TO_CHAR(TO_DATE(maxDate, 'yyyy-mm-dd'), 'dd/mm/yyyy')||'): ', dimensione => 'h3');
                    END IF;
                    gui.AGGIUNGIPARAGRAFO (testo => TRUNC(trendPercent, 2)||'%');

                        gui.AGGIUNGIINTESTAZIONE (testo => 'Clienti poco assidui', dimensione => 'h2');
                        IF(r_DataInizio IS NOT NULL AND r_DataFine IS NOT NULL) THEN
                            gui.AGGIUNGIINTESTAZIONE (testo => 'Top 10 clienti che hanno effettuatto meno ricariche  (' ||TO_CHAR(TO_DATE(r_DataInizio, 'yyyy-mm-dd'), 'dd/mm/yyyy')||' - '||TO_CHAR(TO_DATE(r_DataFine, 'yyyy-mm-dd'), 'dd/mm/yyyy')||'): ', dimensione => 'h3');
                        ELSE
                            gui.AGGIUNGIINTESTAZIONE (testo => 'Top 10 clienti che hanno effettuatto meno ricariche  (' ||TO_CHAR(TO_DATE(minDate, 'yyyy-mm-dd'), 'dd/mm/yyyy')||' - '||TO_CHAR(TO_DATE(maxDate, 'yyyy-mm-dd'), 'dd/mm/yyyy')||'): ', dimensione => 'h3');
                        END IF;
                        head := gui.StringArray('Identificativo','Euro spesi in ricariche');
                        gui.APRITABELLA (elementi => head);
                        for cliente IN (
                                SELECT *
                                FROM (SELECT c.IDCLIENTE, SUM(r.IMPORTO) AS ricaricheTot
                                    FROM Clienti c JOIN RICARICHE r ON (c.IDCLIENTE = r.FK_CLIENTE)
                                    WHERE (TRUNC(r.data) >= TO_DATE(r_DataInizio, 'yyyy-mm-dd') or r_DataInizio is null)
                                        AND (TRUNC(r.data) <= TO_DATE(r_DataFine, 'yyyy-mm-dd') or r_DataFine is null)
                                    GROUP BY c.IDCLIENTE
                                    ORDER BY ricaricheTot)
                                WHERE ROWNUM <=10
                            )
                        LOOP
                            gui.AGGIUNGIRIGATABELLA;
                                gui.aggiungielementotabella(elemento => cliente.IDCLIENTE);
                                gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(cliente.ricaricheTot, 'FM999G999G990D00', 'NLS_NUMERIC_CHARACTERS='',.'' NLS_CURRENCY=''€''')||'€');
                            gui.ChiudiRigaTabella;
                        end LOOP;
                        gui.CHIUDITABELLA();

                    gui.CHIUDIGRUPPOINPUT();
            ELSE
                RAISE NO_DATA_FOUND;
            END IF;
        ELSE
            gui.AGGIUNGIPOPUP(False, 'Errore: non hai i permessi per accedere a questa pagina', costanti.URL||'gui.homepage?idsessione'||idSess);
        END IF;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            gui.AGGIUNGIPOPUP(False, 'Errore: nessun dato presente.');

        END dettagliRicaricheClienti;

        procedure visualizzaClienti(
            idSess SESSIONICLIENTI.IDSESSIONE%TYPE default NULL,
            c_Nome VARCHAR2 default NULL,
            c_Cognome VARCHAR2 default NULL,
            c_DataNascita VARCHAR2 default NULL,
            c_Sesso VARCHAR2 default NULL
        ) IS

        head gui.StringArray; --parametri per headers della tabella

        BEGIN

        gui.apriPagina (titolo => 'visualizza clienti', idSessione => idSess);  --se non loggato porta all'homePage

        if (NOT (SESSIONHANDLER.checkRuolo (idSess, 'Manager') OR SESSIONHANDLER.checkRuolo(idSess, 'Operatore'))) then
                gui.apriPagina (titolo => 'visualizza clienti', idSessione => idSess);
                gui.aggiungiPopup (False, 'Non hai i permessi per accedere a questa pagina', costanti.URL || 'gui.homePage?idSessione='||idSess||'&p_success=S');
                gui.chiudiPagina;
                return;
            end if;
            

            gui.APRIFORMFILTRO;
                gui.aggiungiInput (tipo => 'hidden', value => idSess, nome => 'idSess');
                gui.aggiungicampoformfiltro(nome => 'c_Nome', placeholder => 'Nome');
                gui.aggiungicampoformfiltro( nome => 'c_Cognome', placeholder => 'Cognome');
                gui.aggiungicampoformfiltro(tipo => 'date', nome => 'c_DataNascita', placeholder => 'Birth');
                gui.apriSelectFormFiltro ('c_Sesso', 'Sesso');
                gui.aggiungiOpzioneSelect ('', true, '');
                gui.aggiungiOpzioneSelect ('M', false , 'Maschio');
                gui.aggiungiOpzioneSelect ('F', false , 'Femmina');
                gui.chiudiSelectFormFiltro;
                gui.aggiungicampoformfiltro(tipo => 'submit', value => 'Filtra', placeholder => 'filtra');
            gui.CHIUDIFORMFILTRO;
            gui.aCapo(2);

            head := gui.StringArray('Nome', 'Cognome', 'Sesso', ' ');
            gui.APRITABELLA (elementi => head);

        for clienti IN
        (SELECT IDCLIENTE, Nome, Cognome, DataNascita, Sesso, Ntelefono, Email, Password FROM CLIENTI
                where ( CLIENTI.NOME = c_Nome or c_Nome is null )
                and ( trunc( CLIENTI.DATANASCITA) = to_date(c_DataNascita,'YYYY-MM-DD') OR c_DataNascita is null)
                and ( CLIENTI.COGNOME = c_Cognome or c_Cognome is null )
                and ( CLIENTI.SESSO = c_Sesso or c_Sesso is null )
            )
        LOOP
            gui.AGGIUNGIRIGATABELLA;
                    gui.AGGIUNGIELEMENTOTABELLA(elemento => clienti.nome);
                    gui.AGGIUNGIELEMENTOTABELLA(elemento => clienti.Cognome);
                    gui.AGGIUNGIELEMENTOTABELLA(elemento => clienti.Sesso);

                    gui.APRIELEMENTOPULSANTI;
                    gui.aggiungiPulsanteGenerale (collegamento => ''''|| u_root || '.visualizzaProfilo?idSess='||idSess||'&id='||clienti.IDCLIENTE||'''', testo => 'Profilo');
                    gui.chiudiElementoPulsanti;
            gui.ChiudiRigaTabella;
            end LOOP;

            gui.CHIUDITABELLA;
            gui.ChiudiPagina;

        END visualizzaClienti;

        procedure visualizzaConvenzioni (
            idSess varchar DEFAULT NULL,
            c_DataInizio VARCHAR2 DEFAULT NULL,
            c_DataFine VARCHAR2 DEFAULT NULL,
            c_Ente VARCHAR2 DEFAULT NULL,
            c_Cumulabile VARCHAR2 DEFAULT NULL) is

            head gui.StringArray;

        BEGIN

            gui.apriPagina (titolo => 'visualizza Convenzioni', idSessione => idSess);

            if (NOT (SESSIONHANDLER.checkRuolo (idSess, 'Cliente') OR SESSIONHANDLER.checkRuolo (idSess, 'Operatore') OR SESSIONHANDLER.checkRuolo (idSess, 'Manager'))) then
                gui.aggiungiPopup (False, 'Non hai i permessi per accedere alla seguente pagina', costanti.URL || 'gui.homePage?idSessione='||idSess||'&p_success=S');
                gui.chiudiPagina;
                return;
            end if;

            if SESSIONHANDLER.checkRuolo (idSess, 'Manager') then
                head := gui.StringArray ('Nome', 'Ente', 'Sconto', 'CodiceAccesso', 'DataInizio', 'DataFine', 'Cumulabile',' ');
                else
                head := gui.StringArray ('Nome', 'Ente', 'Sconto', 'DataInizio', 'DataFine', 'Cumulabile');
        end if;

        gui.APRIFORMFILTRO;
        gui.aggiungiInput (tipo => 'hidden', value => idSess, nome => 'idSess');
        gui.AGGIUNGICAMPOFORMFILTRO (tipo => 'date', nome => 'c_DataInizio', placeholder => 'Data-inizio');
        gui.AGGIUNGICAMPOFORMFILTRO (tipo => 'date', nome => 'c_DataFine', placeholder => 'Data-fine');
        gui.AGGIUNGICAMPOFORMFILTRO (nome => 'c_Ente', placeholder => 'Ente');
        gui.apriSelectFormFiltro ('c_Cumulabile', 'Cumulabile');
                gui.aggiungiOpzioneSelect ('', true, '');
                gui.aggiungiOpzioneSelect ('1', false , 'Si');
                gui.aggiungiOpzioneSelect ('0', false , 'No');
                gui.chiudiSelectFormFiltro;
        gui.AggiungiCampoFormFiltro(tipo =>'submit', value => 'Filtra', placeholder => 'Filtra');
        gui.CHIUDIFORMFILTRO;
        gui.aCapo(2);

        gui.APRITABELLA (head);

        for convenzioni IN
        (SELECT * FROM CONVENZIONI where
                ( trunc(CONVENZIONI.DATAINIZIO) = to_date(c_DataInizio,'YYYY-MM-DD') OR c_DataInizio is null)
                and ( trunc(CONVENZIONI.DATAFINE) = to_date(c_DataFine,'YYYY-MM-DD') OR c_DataFine is null)
                and ( CONVENZIONI.ENTE = c_Ente or c_Ente is null )
                and ( CONVENZIONI.CUMULABILE = to_number(c_Cumulabile) or c_Cumulabile is null )
        )
        LOOP
            gui.AGGIUNGIRIGATABELLA;

                        gui.AGGIUNGIELEMENTOTABELLA(elemento => convenzioni.Nome);
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => convenzioni.Ente);
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => convenzioni.Sconto);

                        if SESSIONHANDLER.checkRuolo (idSess, 'Manager') then
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => convenzioni.CodiceAccesso);
                        end if;

                        gui.AGGIUNGIELEMENTOTABELLA(elemento => convenzioni.DataInizio);
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => convenzioni.DataFine);
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => convenzioni.Cumulabile);

                        if SESSIONHANDLER.checkRuolo (idSess, 'Manager') then
                            if (convenzioni.DataInizio >= SYSDATE AND convenzioni.dataFine > SYSDATE) then 
                                gui.apriElementoPulsanti;
                                    gui.aggiungiPulsanteModifica (collegamento => u_root || '.modificaConvenzione?idSess='||idSess||'&c_id='||convenzioni.IDCONVENZIONE||'');
                                gui.chiudiElementoPulsanti;
                            end if; 
                        end if;

            gui.ChiudiRigaTabella;
            end LOOP;

            gui.ChiudiTabella;
            gui.aCapo(2);
            gui.chiudiPagina;

        END visualizzaConvenzioni;

        procedure dettagliConvenzioni (
                idSess SESSIONIDIPENDENTI.IDSESSIONE%TYPE default null,
                c_nome CONVENZIONI.NOME%TYPE default null,
                err_popup varchar2 default null
            ) IS
            c_check boolean := true; --flag per il controllo dell'esistenza della convenzione
            c_id CONVENZIONI.IDCONVENZIONE%TYPE := NULL;
            num_clienti int := 0;
            totale_clienti int := 0;
            percentage decimal (10,2) := 0;
            percentage_convenzione decimal (10,2) := 0;
            BEGIN
                gui.apriPagina (titolo => 'Dettagli convenzioni', idSessione => idSess);

                --controllo manager
                if ( NOT (SESSIONHANDLER.checkRuolo (idSess, 'Manager'))) THEN
                    gui.aggiungiPopup (FALSE, 'Non hai i permessi per accedere a questa pagina', costanti.URL || 'gui.homePage?idSessione='||idSess||'&p_success=S');
                    gui.chiudiPagina;
                    return;
                END IF;

                if err_popup IS NOT NULL THEN
                    if err_popup = 'N' then
                        gui.aggiungiPopup (False, 'Convenzione non trovata');
                        gui.aCapo(2);
                    end if;
                END IF;

                if c_nome is not NULL THEN
                    SELECT IDCONVENZIONE INTO c_id FROM CONVENZIONI WHERE NOME = c_nome;
                    if SQL%ROWCOUNT > 0 THEN --esiste, faccio il calcolo del numero dei clienti e della percentuale

                        --prelevo i dati
                        SELECT COUNT(IDCLIENTE) INTO totale_clienti FROM CLIENTI;
                        if totale_clienti <> 0 then
                            SELECT COUNT(FK_CLIENTE) INTO num_clienti FROM CONVENZIONICLIENTI WHERE FK_CONVENZIONE = c_id;
                            percentage := (num_clienti / totale_clienti) * 100.0;
                        end if;

                        else
                        gui.aggiungiPopup (False, 'Convenzione non esistente');
                        gui.aCapo(2);
                        c_check:=false;
                    end if;
                END IF;

                gui.aggiungiForm;
                
                        gui.aggiungiIntestazione (testo => 'Dettagli statistici');
                        gui.aggiungiIntestazione (testo => 'convenzioni');
                            
                    gui.aCapo();

                    gui.aggiungiIntestazione( testo => 'Immetti il nome di una convenzione', dimensione => 'h2');
                    --gui.aCapo();

                    --filtro per nome le convenzioni e guardo quanti clienti le utilizzano
                    gui.apriFormFiltro;
                        gui.aggiungiInput (tipo => 'hidden', nome => 'idSess', value => idSess);
                        gui.aggiungiCampoFormFiltro (nome => 'c_nome', placeholder => 'Nome convenzione');
                        gui.aggiungiCampoFormFiltro (tipo => 'submit', placeholder => 'filtra');
                    gui.chiudiFormFiltro;
                    gui.aCapo(2);


                    if c_nome IS NOT NULL AND c_check then
                    --visualizzo i dati
                    gui.aggiungiGruppoInput;
                        gui.aggiungiIntestazione( testo => 'Dati su '|| c_nome || '', dimensione => 'h1');

                        gui.aCapo(2);
                        gui.apridiv (classe => 'flex-container');
                            gui.apridiv (classe => 'left');
                                gui.aggiungiIntestazione( testo => 'Clienti che la usano', dimensione => 'h2');
                            gui.chiudiDiv;
                            gui.apridiv (classe => 'right');
                                gui.aggiungiIntestazione( testo => ''||num_clienti||'', dimensione => 'h2');
                            gui.chiudiDiv;

                            gui.aCapo(2);

                            gui.apridiv (classe => 'left');
                                gui.aggiungiIntestazione( testo => 'In percentuale', dimensione => 'h2');
                            gui.chiudiDiv;
                            gui.apridiv (classe => 'right');
                                gui.aggiungiIntestazione( testo => ''||percentage||'%', dimensione => 'h2');
                            gui.chiudiDiv;

                            --tabella che visualizza le prime tre convenzioni più utilizzate

                            gui.aggiungiIntestazione( testo => 'Top 3 convenzioni più usate', dimensione => 'h2');
                            gui.aCapo;
                            gui.apriTabella (elementi => gui.StringArray('Nome', 'Percentuale', 'Numero clienti'));
                            for convenzione in (
                                SELECT c.IDconvenzione,
                                                c.Nome,
                                                COUNT(ci.FK_Convenzione) AS NumeroClientiUtilizzatori
                                                FROM CONVENZIONI c
                                                JOIN CONVENZIONICLIENTI ci ON c.IDconvenzione = ci.FK_Convenzione
                                                GROUP BY c.IDconvenzione, c.Nome, c.Ente
                                                ORDER BY COUNT(ci.FK_Convenzione) DESC
                                                FETCH FIRST 3 ROWS ONLY

                            ) LOOP
                            gui.AggiungiRigaTabella;

                                percentage_convenzione := (convenzione.NumeroClientiUtilizzatori / totale_clienti) * 100.0;
                                gui.aggiungiElementoTabella (elemento => convenzione.Nome);
                                gui.aggiungiElementoTabella (elemento => ''||percentage_convenzione||'%');
                                gui.aggiungiElementoTabella (elemento => convenzione.NumeroClientiUtilizzatori);

                            gui.chiudiRigaTabella;
                            END LOOP;
                            gui.chiudiTabella;

                        gui.chiudiDiv; --flex-container
                    gui.chiudiGruppoInput;
                    else 
                        gui.aCapo(); 
                        gui.bottoneAggiungi (testo => 'Visualizza convenzioni', url => u_root || '.visualizzaConvenzioni?idSess='||idSess||'');
                    end if;

                gui.chiudiForm;

                gui.aCapo(2);
                gui.chiudiPagina;

                EXCEPTION
                    when NO_DATA_FOUND THEN
                    gui.reindirizza (u_root || '.dettagliConvenzioni?idSess='||idSess||'&err_popup=N');
                END dettagliConvenzioni;

    procedure dettagliCategorieClienti(
                idSess varchar default null,
                c_datainizio varchar2 default null,
                c_datafine varchar2 default null,
                c_sesso varchar2 default null,
                err_popup varchar2 default null,
                filtro varchar2 default null
            ) IS
            tot_catClienti int;
            tot_clienti int; 
            percentage decimal (10,2) := 0;
            percentage_cliente decimal (10,2) := 0;
            c_check boolean := false; 

            BEGIN
                gui.apriPagina (titolo => 'Dettagli clienti', idSessione => idSess);

                --controllo manager
                if ( NOT (SESSIONHANDLER.checkRuolo (idSess, 'Manager'))) THEN
                    gui.aggiungiPopup (FALSE, 'Non hai i permessi per accedere a questa pagina', costanti.URL || 'gui.homePage?idSessione='||idSess||'&p_success=S');
                    gui.chiudiPagina;
                    return;
                END IF;

                if err_popup IS NOT NULL then 
                    if err_popup = 'N' then 
                        gui.aggiungiPopup (False, 'Nessuna categoria trovata'); 
                        gui.aCapo(2); 
                    end if; 
                end if; 

            SELECT COUNT(*) INTO tot_clienti FROM CLIENTI; 
            
                if c_datainizio IS NOT NULL OR c_datafine IS NOT NULL OR c_sesso IS NOT NULL then 
                    c_check := true;
                else
                    SELECT COUNT(DISTINCT cc.FK_CLIENTE) INTO tot_catCLienti
                            FROM CONVENZIONICLIENTI cc INNER JOIN CLIENTI cl ON cc.FK_CLIENTE = cl.IDCLIENTE;
                end if; 
                         
                if c_check then   

                    if (c_dataInizio IS NOT NULL) AND (c_dataFine IS NOT NULL) AND (c_sesso IS NOT NULL) then 
                        SELECT COUNT(DISTINCT cc.FK_CLIENTE) INTO tot_catCLienti
                            FROM CONVENZIONICLIENTI cc INNER JOIN CLIENTI cl ON cc.FK_CLIENTE = cl.IDCLIENTE WHERE 1=1
                                AND cl.DataNascita >= TO_DATE(c_datainizio,'YYYY-MM-DD')  AND cl.DataNascita <= TO_DATE(c_dataFine, 'YYYY-MM-DD') AND cl.Sesso = c_sesso;
                    elsif (c_dataInizio IS NOT NULL) AND (c_dataFine IS NOT NULL) then 
                        SELECT COUNT(DISTINCT cc.FK_CLIENTE) INTO tot_catCLienti
                            FROM CONVENZIONICLIENTI cc INNER JOIN CLIENTI cl ON cc.FK_CLIENTE = cl.IDCLIENTE WHERE 1=1
                                AND cl.DataNascita >= TO_DATE(c_datainizio,'YYYY-MM-DD')  AND cl.DataNascita <= TO_DATE(c_dataFine, 'YYYY-MM-DD'); 
                    elsif (c_dataInizio IS NOT NULL) AND (c_sesso IS NOT NULL) then 
                        SELECT COUNT(DISTINCT cc.FK_CLIENTE) INTO tot_catCLienti
                            FROM CONVENZIONICLIENTI cc INNER JOIN CLIENTI cl ON cc.FK_CLIENTE = cl.IDCLIENTE WHERE 1=1
                                AND cl.DataNascita >= TO_DATE(c_datainizio,'YYYY-MM-DD') AND cl.Sesso = c_sesso;
                    elsif (c_dataFine IS NOT NULL) AND (c_sesso IS NOT NULL) then 
                        SELECT COUNT(DISTINCT cc.FK_CLIENTE) INTO tot_catCLienti
                            FROM CONVENZIONICLIENTI cc INNER JOIN CLIENTI cl ON cc.FK_CLIENTE = cl.IDCLIENTE WHERE 1=1
                                AND cl.DataNascita <= TO_DATE(c_dataFine, 'YYYY-MM-DD') AND cl.Sesso = c_sesso;
                    elsif c_dataInizio IS NOT NULL then  
                        SELECT COUNT(DISTINCT cc.FK_CLIENTE) INTO tot_catCLienti
                            FROM CONVENZIONICLIENTI cc INNER JOIN CLIENTI cl ON cc.FK_CLIENTE = cl.IDCLIENTE WHERE 1=1
                                AND cl.DataNascita >= TO_DATE(c_datainizio,'YYYY-MM-DD');
                    elsif c_dataFine IS NOT NULL then  
                        SELECT COUNT(DISTINCT cc.FK_CLIENTE) INTO tot_catCLienti
                            FROM CONVENZIONICLIENTI cc INNER JOIN CLIENTI cl ON cc.FK_CLIENTE = cl.IDCLIENTE WHERE 1=1
                                AND cl.DataNascita <= TO_DATE(c_dataFine, 'YYYY-MM-DD');
                    elsif c_sesso IS NOT NULL then  
                        SELECT COUNT(DISTINCT cc.FK_CLIENTE) INTO tot_catCLienti
                            FROM CONVENZIONICLIENTI cc INNER JOIN CLIENTI cl ON cc.FK_CLIENTE = cl.IDCLIENTE WHERE 1=1
                                AND cl.Sesso = c_sesso;
                    end if; 
                end if;

                percentage := (tot_catClienti / tot_clienti) * 100.0; 

                --fin qui ok
                gui.aggiungiForm;
                    gui.aggiungiIntestazione (testo => 'Dettagli statistici');
                    gui.aggiungiIntestazione (testo => 'clienti');
                    gui.aCapo();

                    gui.aggiungiIntestazione (testo => 'Seleziona una categoria di clienti', dimensione => 'h2');

                gui.APRIFORMFILTRO();
                    gui.AGGIUNGIINPUT(tipo => 'hidden', nome => 'idSess', value => idSess);
                        gui.aggiungicampoformfiltro(tipo => 'date', nome => 'c_datainizio', placeholder => 'Data Inizio');
                        gui.aggiungicampoformfiltro(tipo => 'date', nome => 'c_datafine', placeholder => 'Data Fine');
                        gui.apriSelectFormFiltro ('c_Sesso', 'Sesso');
                            gui.aggiungiOpzioneSelect ('', true, '');
                            gui.aggiungiOpzioneSelect ('M', false , 'Maschio');
                            gui.aggiungiOpzioneSelect ('F', false , 'Femmina');
                        gui.chiudiSelectFormFiltro;
                        gui.aggiungicampoformfiltro('submit', 'filtro', 'on', 'Filtra');
                    gui.ACAPO;
                gui.CHIUDIFORMFILTRO;

                if tot_catClienti <> 0 AND filtro = 'on' then 
                gui.aCapo;
                gui.aggiungiIntestazione( testo => 'Dati sulla categoria');
                    gui.aggiungiGruppoInput;
                        gui.aCapo(2); 
                        gui.apridiv (classe => 'flex-container');
                            gui.apriDiv (classe => 'left'); 
                                gui.aggiungiIntestazione (testo => 'Clienti che usano convenzioni', dimensione => 'h2');
                            gui.chiudiDiv; 
                            gui.apriDiv (classe => 'right');
                                gui.aggiungiIntestazione (testo => '' || tot_catClienti  || '', dimensione => 'h2');
                            gui.chiudiDiv; 

                            gui.acapo;

                            gui.apriDiv (classe => 'left'); 
                                gui.aggiungiIntestazione (testo => 'In percentuale', dimensione => 'h2');
                            gui.chiudiDiv; 
                            gui.apriDiv (classe => 'right');
                                gui.aggiungiIntestazione (testo => '' || percentage || '%', dimensione => 'h2');
                            gui.chiudiDiv; 

                            gui.acapo;

                            gui.aggiungiIntestazione( testo => 'Top 3 clienti più attivi (per convenzioni)', dimensione => 'h2');
                            gui.aCapo;

                            gui.apriTabella (elementi => gui.StringArray('Nome', 'Percentuale', 'Numero convenzioni'));
                            for cliente in (
                                SELECT c.IDCliente,
                                                c.Nome,
                                                COUNT(DISTINCT ci.FK_Convenzione) AS NumeroConvenzioniUsate
                                                FROM CLIENTI c
                                                JOIN CONVENZIONICLIENTI ci ON c.IDCliente = ci.FK_Cliente
                                                GROUP BY c.IDCliente, c.Nome
                                                ORDER BY COUNT(ci.FK_Convenzione) DESC
                                                FETCH FIRST 3 ROWS ONLY

                            ) LOOP
                            gui.AggiungiRigaTabella;
                                percentage_cliente := (cliente.NumeroConvenzioniUsate / tot_clienti) * 100.0;
                                gui.aggiungiElementoTabella (elemento => cliente.Nome);
                                gui.aggiungiElementoTabella (elemento => ''||percentage_cliente ||'%');
                                gui.aggiungiElementoTabella (elemento => cliente.NumeroConvenzioniUsate);

                            gui.chiudiRigaTabella;
                            END LOOP; 
                            gui.chiudiTabella; 

                        gui.chiudiDiv; --flex-container
                    gui.chiudiGruppoInput;
                    else 

                    gui.aCapo(3); 
                    gui.bottoneAggiungi (testo => 'Visualizza clienti', url => u_root || '.visualizzaClienti?idSess='||idSess||'');
                end if; 
 
                gui.chiudiForm;

                if tot_catClienti = 0 then 
                    gui.reindirizza (u_root || '.dettagliCategorieClienti?idSess='||idSess||'&err_popup=N');
                    return; 
                end if; 

                gui.aCapo(2);
                gui.chiudiPagina;

                EXCEPTION
                    when NO_DATA_FOUND THEN
                        gui.reindirizza (u_root || '.dettagliCategorieClienti?idSess='||idSess||'&err_popup=N');
            END dettagliCategorieClienti;
    
        end gruppo3;

