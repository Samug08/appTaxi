--SET DEFINE OFF;
create or replace PACKAGE BODY gui as

	procedure Reindirizza(indirizzo varchar2) is
	begin
		htp.prn('<head><meta http-equiv="refresh" content="0;url=' || indirizzo || '"></head>');
	end Reindirizza;

	procedure ApriPagina(titolo varchar2 default 'Senza titolo', idSessione VARCHAR default '-1',  scriptJS VARCHAR2 default '', defaultModal boolean default true) is
	begin
		htp.htmlOpen;
		htp.headOpen;
		htp.title(titolo);
		htp.print('
			<meta charset="utf-8">
			<meta name="viewport" content="width=device-width, initial-scale=1">
		');
		htp.prn('<link rel="icon" type="image/x-icon" href="https://drive.google.com/thumbnail?id=1GFHoVYrWo5xBrHAO0u1NWeh0FcTISR5n">');
		htp.prn('<link href="https://cdn.jsdelivr.net/npm/simple-datatables@latest/dist/style.css" rel="stylesheet" type="text/css">
				<script src="https://cdn.jsdelivr.net/npm/simple-datatables@latest" type="text/javascript"></script>
				<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>');
		htp.print('<style> ' || costanti.stile || '</style>');
		htp.print('<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
			'); /*FONTAwesome*/
		htp.print('<script type="text/javascript">' || costanti.scriptjs || CHR(10) || scriptJS || CHR(10)|| costanti.dropdownScript ||  CHR(10) || '  
		
					//Variabili per paginazione
					const Http = new XMLHttpRequest(); // Richieste http
					var currentTableRequest = null;    // Tabella che richiese nuovi elementi
					var dataTables = {};			   // lista di oggetti DataTables
		
					</script>'); -- Aggiunto script di base
		htp.headClose;
		gui.ApriBody(idSessione, defaultModal);
	end Apripagina;

	procedure ApriBody(idSessione varchar2, defaultModal boolean default true) is
		username VARCHAR2(20);
	begin

		htp.print('<body>');
		
		if defaultModal then
			gui.modalPopup;
		end if; 

		if idSessione = '-1' then --Sessione ospite
			gui.topbar(-1, '', '');	

			gui.ApriDiv('', 'container');
				gui.ApriDiv('', 'contentContainer');
			return;
		end if;

		if not SessionHandler.checkSession(idSessione) then 
			gui.Reindirizza(costanti.URL||'gui.homePage?p_success=T');
			return;
		end if;
		
		gui.TopBar(SessionHandler.getIdUser(idSessione), SessionHandler.getUsername(idSessione), SessionHandler.getRuolo(idSessione), idSessione);

		-- modal popup (nascosto)

		gui.ApriDiv('', 'container');
			gui.ApriDiv('', 'contentContainer');

	end ApriBody;

	procedure ChiudiPagina(scriptJS VARCHAR2 default '') is
	begin
		htp.prn('</div>'); /*container*/
		htp.prn('</div>'); /*content-container*/
		gui.Footer;
		htp.prn('<script>'|| scriptJS ||'

		function sendRequest(p_offset){
			Http.open("GET", window.location.href+"&p_offset="+(p_offset).toString());
			Http.send();
		}

		Http.onreadystatechange = function() {
			if(this.readyState==4 && this.status==200){
				const newTRs = new DOMParser().parseFromString(Http.responseText, "text/html").querySelector("#"+currentTableRequest.table.dom.id).querySelectorAll("tr");

				let newData = { data : [] };

				for(let i = 1; i < newTRs.length; i++){
					
					var rowData = [];

					newTRs[i].childNodes.forEach(td => {
						rowData.push(td.innerHTML);
					})


					newData.data.push(rowData);
				}

				if (newTRs.length < 31) currentTableRequest.fetchedAll = true;
				
				currentTableRequest.table.insert(newData);

			}
		}

		window.onclick = function(event) {
			const modals = document.getElementsByClassName("modal-wrapper");

			for(modal of modals){
				if (event.target == modal) {
					modal.style.display = "none";
				}
			}

		}

		</script>');
		htp.print('</body>');

	end ChiudiPagina;

	procedure indirizzo(indirizzo VARCHAR2 default '') is
	begin
		htp.prn('<a href="'|| indirizzo ||'">');
	end indirizzo;

	procedure chiudiIndirizzo is
	begin
		htp.prn('</a>');
	end chiudiIndirizzo;

	procedure modalPopup (
		testo varchar2 default ''
	)IS
	BEGIN 
		gui.apriDiv (classe => 'modal-wrapper', ident => 'modal');
			gui.apriDiv (classe => 'modal');
				gui.aggiungiIntestazione (testo => 'Sei sicuro?');
				gui.aCapo(); 
				
				gui.apriDiv (classe => 'modal-button');  -- Bottoni si no
				gui.chiudiDiv;
			gui.chiudiDiv;
		gui.chiudiDiv;
		
	END modalPopup; 

	procedure apriModalPopup (
		testo varchar2 default '',
		ident varchar2 default 'modal'
	)is
	BEGIN 
		gui.apriDiv (classe => 'modal-wrapper', ident => ident);
		gui.apriDiv (classe => 'modal');
			gui.aggiungiIntestazione (testo => testo);
			gui.aCapo();  
		
	END apriModalPopup;

	procedure chiudiModalPopup is
	BEGIN 

		gui.chiudiDiv;
		gui.chiudiDiv;
		
	END chiudiModalPopup;
	

	procedure BottoneTopBar(testo varchar2 default '', nome varchar2 default '', valore varchar2 default '') is
	begin
		htp.prn('<button type="submit" ');
		
		if ((nome != '' and nome is not null) and (valore != '' and valore is not null)) then
			htp.prn('name="' || nome || '"  value="' || valore || '" ');
		end if;
		
		htp.prn(' class="button-48">');
		htp.prn('<span class="text">'); 
		htp.prn(testo);
		htp.prn('</span>');
		htp.prn('</button>');

	end BottoneTopBar;

	procedure BottonePrimario(testo varchar2 default '', nome varchar2 default '', valore varchar2 default '') is
	begin
		htp.prn('<button type="submit" ');
		
		if ((nome != '' and nome is not null) and (valore != '' and valore is not null)) then
			htp.prn('name="' || nome || '"  value="' || valore || '" ');
		end if;
		
		htp.prn(' class="bottone">');
		htp.prn('<span class="text">'); 
		htp.prn(testo);
		htp.prn('</span>');
		htp.prn('</button>');

	end BottonePrimario;

	procedure ApriDiv(ident varchar2 default '', classe varchar2 default '', onclick varchar2 default '') is
	begin
		htp.print('<div');
		if ident is not null then
			htp.print(' id="' || ident || '"');
		end if;
		if classe is not null then
			htp.print(' class="' || classe || '"');
		end if;
		if onclick is not null then
			htp.print(' onclick="'||onclick||'"');
		end if;
		htp.print('>');

	end ApriDiv;

	procedure ChiudiDiv is
	begin
		htp.print('</div>');

	end ChiudiDiv;

	procedure TopBar(id_user int, username VARCHAR2, ruolo VARCHAR2, idSessione varchar2 default null) is
		saldo_ CLIENTI.SALDO%TYPE;
	BEGIN
		saldo_ := null;
		gui.ApriDiv(ident => 'top-bar');

		gui.APRIDIV(ident => 'bottoneSinistra');
			gui.apriDiv(classe => 'topbar-dropdown');
				gui.BottoneTopBar(testo => 'Gruppo 1');
				gui.apriDiv(ident => 'topbardropdown-content', classe => 'topbardropdown-content');
					for url in (SELECT * FROM PERMISSIONS WHERE PERMISSIONS.NUMBERGROUP=1) loop
						gui.indirizzo(url.PROCEDUREURL||idSessione);
							htp.prn('<span>'||url.name||'</span>');
						gui.chiudiIndirizzo;
					end loop;
				gui.chiudiDiv();
			gui.chiudiDiv();


			gui.apriDiv(classe => 'topbar-dropdown');
				gui.BottoneTopBar(testo => 'Gruppo 2');
				gui.apriDiv(ident => 'topbardropdown-content', classe => 'topbardropdown-content');
						for url in (SELECT * FROM PERMISSIONS WHERE PERMISSIONS.NUMBERGROUP=2) loop
						gui.indirizzo(url.PROCEDUREURL||idSessione);
							htp.prn('<span>'||url.name||'</span>');
						gui.chiudiIndirizzo;
					end loop;
				gui.chiudiDiv();
			gui.chiudiDiv();

			gui.apriDiv(classe => 'topbar-dropdown');
				gui.BottoneTopBar(testo => 'Gruppo 3');
				gui.apriDiv(ident => 'topbardropdown-content', classe => 'topbardropdown-content');
					for url in (SELECT * FROM PERMISSIONS WHERE PERMISSIONS.NUMBERGROUP=3) loop
						gui.indirizzo(url.PROCEDUREURL||idSessione);
							htp.prn('<span>'||url.name||'</span>');
						gui.chiudiIndirizzo;
					end loop;
				gui.chiudiDiv();
			gui.chiudiDiv();

		    gui.apriDiv(classe => 'topbar-dropdown');
				gui.BottoneTopBar(testo => 'Gruppo 4');
				gui.apriDiv(ident => 'topbardropdown-content', classe => 'topbardropdown-content');
					for url in (SELECT * FROM PERMISSIONS WHERE PERMISSIONS.NUMBERGROUP=4) loop
						gui.indirizzo(url.PROCEDUREURL||idSessione);
							htp.prn('<span>'||url.name||'</span>');
						gui.chiudiIndirizzo;
					end loop;
				gui.chiudiDiv();
			gui.chiudiDiv();

			gui.apriDiv(classe => 'topbar-dropdown');
				gui.BottoneTopBar(testo => 'Gruppo Inserimento dati');
				gui.apriDiv(ident => 'topbardropdown-content', classe => 'topbardropdown-content');
					for url in (SELECT * FROM PERMISSIONS WHERE PERMISSIONS.NUMBERGROUP=5) loop
						gui.indirizzo(url.PROCEDUREURL||idSessione);
							htp.prn('<span>'||url.name||'</span>');
						gui.chiudiIndirizzo;
					end loop;
				gui.chiudiDiv();
			gui.chiudiDiv();

		gui.CHIUDIDIV;
		
		if id_user = -1 then 
			gui.ChiudiDiv();
			return;
		end if;

		gui.APRIDIV(classe=> 'bottoniDestra');

			if ruolo = 'Cliente' then
				SELECT SALDO into saldo_ FROM CLIENTI WHERE IDCLIENTE = id_user;
			end if;

			if saldo_ is not null then
				gui.BottonePrimario(testo => 'Saldo: ' || saldo_ || '€');
			end if;

			gui.bottonePrimario(testo => username ||' | '||ruolo);

			--gui.indirizzo('Link to logica logout');
				
			gui.indirizzo(costanti.URL||'gui.LogOut?idSessione='||idSessione);
				gui.BottonePrimario(testo => 'Logout'); 
			gui.chiudiIndirizzo;

				--bottone homepage
			gui.indirizzo (costanti.URL || 'gui.homePage?p_success=S&idSessione='||idSessione||'');
			gui.bottonePrimario(testo => 'Home');
			gui.chiudiIndirizzo; 
			
			--gui.chiudiIndirizzo;
		gui.CHIUDIDIV;

		gui.ChiudiDiv();
	end TopBar;

	procedure dropdowntopbar (
		titolo varchar2 default 'esempio', 
		names stringarray default emptyarray,
		proceduresNames stringarray default emptyarray
	)IS
	BEGIN
		if names.count = proceduresNames.count then 
			gui.apriDiv(classe => 'topbar-dropdown');
				gui.BottoneTopBar(testo => titolo);
				gui.apriDiv(ident => 'topbardropdown-content', classe => 'topbardropdown-content');
					for i in 1..names.count  loop
						gui.indirizzo(''||costanti.URL || proceduresNames(i)||''); --da rivedere
							htp.prn('<span>'||names(i)||'</span>');
						gui.chiudiIndirizzo;
					end loop;
				gui.chiudiDiv();
			gui.chiudiDiv();
		end if; 
		

		END dropdowntopbar;

	-- Procedura Tabella senza filtro provvisoria
	procedure ApriTabella(elementi StringArray default emptyArray, ident varchar2 default null) is
	begin
		htp.prn('<table id="tableN'||ident||'" class="tab"> ');
		htp.prn('<thead>');
		htp.prn('<tr>');
		for i in 1..elementi.count loop
			htp.prn('<th');
			
				if elementi(i) = ' ' then
					htp.prn(' data-sortable="false" ');
				end if;
				htp.prn('>
					'|| elementi(i) || '
				</th>');
		end loop;
		htp.prn('</thead>');
		htp.prn('<tbody>');
	end ApriTabella;

		procedure ChiudiTabella(ident varchar2 default null, SQLpagination boolean default false) IS
	BEGIN
		htp.prn('</tbody>');
		htp.prn('</table>');

		htp.prn('<script>');

		-- Creazione degli elementi grafici e della struttura interna della tabella
		htp.prn('const dataTableN'||ident||' = new simpleDatatables.DataTable("#tableN'||ident||'", {
					responsive: true,
					sortable:true,
					searchable: false,
					perPageSelect: false,
					searchQuerySeparator: ",",
					paging: true,
					locale: "it",
					fixedHeight: true
        		});
		');

		if SQLpagination then
			htp.prn('
					// Inserisco la nuova tabella nella lista delle tabelle.
					dataTables.N'||ident||' = { table : dataTableN'||ident||', offset : 0, fetchedAll : false };

					// Funzione che controlla chiede i nuovi dati se sono all`ultima pagina e se non ho già ricevuto tutti gli elementi

					dataTableN'||ident||'.on("datatable.page", function(page) {
						if(dataTableN'||ident||'.onLastPage && !dataTables.N'||ident||'.fetchedAll ){

							dataTables.N'||ident||'.offset += 30;
							currentTableRequest = dataTables.N'||ident||';

							sendRequest(dataTables.N'||ident||'.offset);

						}
					});
			');
		end if;

		htp.prn('</script>');
	end ChiudiTabella;

	procedure AggiungiRigaTabella IS
	BEGIN
		htp.prn('<tr>');
	end AggiungiRigaTabella;

procedure ChiudiRigaTabella IS
BEGIN
	htp.prn('</tr>');
end ChiudiRigaTabella;

procedure AggiungiPulsanteModifica(collegamento VARCHAR2 default '') IS
BEGIN
	htp.prn('<a href="'||collegamento||'">
		<button>
		<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24"><path fill="currentColor" fill-opacity="0" d="M20 7L17 4L15 6L18 9L20 7Z"><animate fill="freeze" attributeName="fill-opacity" begin="1.2s" dur="0.15s" values="0;0.3"/></path><g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path stroke-dasharray="20" stroke-dashoffset="20" d="M3 21H21"><animate fill="freeze" attributeName="stroke-dashoffset" dur="0.3s" values="20;0"/></path><path stroke-dasharray="44" stroke-dashoffset="44" d="M7 17V13L17 3L21 7L11 17H7"><animate fill="freeze" attributeName="stroke-dashoffset" begin="0.4s" dur="0.6s" values="44;0"/></path><path stroke-dasharray="8" stroke-dashoffset="8" d="M14 6L18 10"><animate fill="freeze" attributeName="stroke-dashoffset" begin="1s" dur="0.2s" values="8;0"/></path></g></svg>
		</button></a>');
END AggiungiPulsanteModifica;

procedure AggiungiPulsanteCancellazione(collegamento VARCHAR2 DEFAULT '', ident_modal varchar2 default 'modal') IS
BEGIN
    htp.prn('<button onclick="mostraConferma('||collegamento||', '||CHR(39)||ident_modal||CHR(39)||')">
    <svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
    <path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16l-1.58 14.22A2 2 0 0 1 16.432 22H7.568a2 2 0 0 1-1.988-1.78zm3.345-2.853A2 2 0 0 1 9.154 2h5.692a2 2 0 0 1 1.81 1.147L18 6H6zM2 6h20m-12 5v5m4-5v5"/>
    </svg>
    </button>');
END AggiungiPulsanteCancellazione;

procedure AggiungiPulsanteGenerale(collegamento VARCHAR2 DEFAULT '', testo VARCHAR2, ident_modal varchar2 default 'modal') IS
BEGIN
    htp.prn('<button onclick="mostraConferma('||collegamento||', '||CHR(39)||ident_modal||CHR(39)||')">
    '||testo||'
    </button>');
END AggiungiPulsanteGenerale;

	procedure AggiungiElementoTabella(elemento VARCHAR2 default '') IS
	BEGIN
		htp.prn('<td>'|| elemento || '</td>');
	end AggiungiElementoTabella;


	procedure ApriFormFiltro(azione VARCHAR default '') IS
	begin
		htp.prn('<form action="'|| azione ||'" method="get">
					<table class="inputTAB">');
	end ApriFormFiltro;

	procedure AggiungiCampoFormFiltro(tipo VARCHAR2 default 'text', nome VARCHAR2, value VARCHAR2 default '',  placeholder VARCHAR2 default '', required BOOLEAN default false, classe VARCHAR2 default '', ident VARCHAR2 default '', pattern VARCHAR2 default '', minimo VARCHAR2 default '', massimo VARCHAR2 default '', readonly boolean default false) IS
	begin
		if(tipo = 'submit') then
		
			htp.prn('<td>
					<div class="formField">
						<label class="hidden" id="'||nome||'">_</label>
						<button class="FilterButton" name="'||nome||'" value="'||value||'">'||placeholder||'</button>
					</div>
				</td>');
		else 
			htp.prn('<td>
				<div class="formField">
					<label  id="'||ident||'">'||placeholder||'</label>');
					gui.aggiungiInput(tipo, nome, value ,'', required, 'filterInput', ident, pattern, minimo, massimo, readonly);
				htp.prn('</div>
			</td>');
		end if;
	end AggiungiCampoFormFiltro;

	procedure AggiungiCampoFormHidden(tipo VARCHAR2 default 'text', nome VARCHAR2, value VARCHAR2 default '', ident varchar2 default '') is
	BEGIN
		htp.prn('<input hidden type="'||tipo||'" name="'|| nome ||'" value="'||value||'" id="'||ident||'">');
	end AggiungiCampoFormHidden;

	procedure ApriSelectFormFiltro(nome varchar2, placeholder VARCHAR2, firstNull boolean default True) IS
	begin
		htp.prn('<td> <div class="formField">
					<label id="'||nome||'">'||placeholder||'</label>
					<select name="'|| nome ||'">');
		if firstNull then
			htp.prn('<option value=""></option>');
		end if;
	end ApriSelectFormFiltro;

	procedure AggiungiOpzioneSelect(value VARCHAR2, selected BOOLEAN, testo VARCHAR2 default '') as
	BEGIN
		if selected then
			htp.prn('<option value="'|| value ||'" selected >' || testo ||' </option>');
		else
			htp.prn('<option value="'|| value ||'">' || testo ||' </option>');
		end if;
	END AggiungiOpzioneSelect;

	procedure ChiudiSelectFormFiltro IS
	begin
		htp.prn(' </select> </div> </td> ');
	end ChiudiSelectFormFiltro;

	procedure chiudiFormFiltro IS
	begin
		htp.prn('</table> </form>');
	end chiudiFormFiltro;

	procedure aggiungiDropdownFormFiltro(testo VARCHAR2 default 'testo', placeholder VARCHAR2 default 'testo', ids stringArray default emptyArray ,names stringArray default emptyArray, hiddenParameter varchar2 default '') is 
		begin

			htp.prn('<td>
					<div class="formField">');
			if placeholder is not null then
				htp.prn('<label >'||placeholder||'</label>');
			else htp.prn('<label class="hidden" >_</label>');
			end if;
			
			gui.apriDiv(classe => 'multiSelect');
				gui.apriDiv(classe => 'multiSelectBtn', onclick => 'apriMultiSelect(this.parentNode)');
					htp.prn('<span class="text">'|| testo ||'</span>');
					htp.prn('<span class="arrow"></span>');
				htp.prn('</div>');
				gui.apriDiv(ident => 'multiSelect-content', classe => 'multiSelect-content');
				
				for i in 1..ids.count loop
					gui.apriDiv(ident => 'option');
						htp.prn('<label for="'||ids(i)||'">'|| names(i) ||'</label>');
						htp.prn('<input type="checkbox" id="' ||ids(i)|| '" value="' ||ids(i)||'" onchange="updateHiddenInput('||chr(39)||hiddenParameter||chr(39)||', this)"/>');
					gui.chiudiDiv();
				end loop;
				
				gui.chiudiDiv();
			gui.chiudiDiv();
						
			htp.prn('</div> </td>');
	end aggiungiDropdownFormFiltro;

	procedure aggiungiIntestazione(testo VARCHAR2 default 'Intestazione', dimensione VARCHAR2 default 'h1', class VARCHAR2 default '') is
	begin
		htp.prn('<'||dimensione||' class="'||class||'">'||testo||'</'||dimensione||'>');
	end aggiungiIntestazione;

	procedure aggiungiParagrafo(testo VARCHAR2 default 'testo', class VARCHAR2 default '') is
	begin
		htp.prn('<p class='||class||' >'||testo||'</p>');
	end aggiungiParagrafo;

	procedure aggiungiDropdown(testo VARCHAR2 default 'testo', opzioni stringArray default null) is
	BEGIN
		gui.apriDiv(classe => 'dropdown');
			gui.apriDiv(classe => 'dropbtn', onclick => 'apriMenu(this.parentNode)');
				htp.prn('<span class="text"></span>');
				htp.prn('<span class="arrow"></span>');
			htp.prn('</div>');
			gui.apriDiv(ident => 'dropdown-content', classe => 'dropdown-content');
			for i in 1..opzioni.count loop
				gui.apriDiv(ident => 'option');
					htp.prn('<input type="checkbox" id="'|| opzioni(i) ||'" />');
					htp.prn('<label for="'|| opzioni(i) ||'">'|| opzioni(i) ||'</label>');
				gui.chiudiDiv();
			end loop;
			gui.chiudiDiv();
		gui.chiudiDiv();
	END aggiungiDropdown;

	procedure aggiungiSelezioneSingola(elementi StringArray, valoreEffettivo StringArray default null, titolo varchar2 default '', ident varchar2, optionSelected varchar2 default null, firstNull boolean default true) IS
		BEGIN
			gui.aggiungiGruppoInput();
			htp.prn('<label for="'||ident||'">'||titolo||'</label><br>');
			htp.prn('<select id="'||ident||'" name="'||ident||'">');
			if firstNull then
				htp.prn('<option value=""></option>');
			end if;
			if valoreEffettivo is null THEN
				for elem in elementi.FIRST..elementi.LAST
				LOOP
					IF optionSelected IS NOT NULL AND elementi(elem) = optionSelected THEN
						htp.prn('<option value="'||elementi(elem)||'" selected="selected">'||elementi(elem)||'</option>');
					ELSE
						htp.prn('<option value="'||elementi(elem)||'">'||elementi(elem)||'</option>');
					end if;
				END LOOP;
			else
				for elem in elementi.FIRST..elementi.LAST
				LOOP
					IF optionSelected IS NOT NULL AND valoreEffettivo(elem) = optionSelected THEN
						htp.prn('<option value="'||valoreEffettivo(elem)||'"  selected="selected">'||elementi(elem)||'</option>');
					ELSE
						htp.prn('<option value="'||valoreEffettivo(elem)||'">'||elementi(elem)||'</option>');
					end if;
				END LOOP;
			end if;
			htp.prn('</select>');
			gui.chiudiGruppoInput;
	END aggiungiSelezioneSingola;

	PROCEDURE aggiungiSelezioneMultipla(
		testo VARCHAR2 DEFAULT 'testo',
		placeholder VARCHAR2 DEFAULT 'testo',
		ids stringArray DEFAULT emptyArray,
		names stringArray DEFAULT emptyArray,
		hiddenParameter VARCHAR2 DEFAULT '',
		parametriSelezionati StringArray default gui.StringArray(),
		ident VARCHAR2 default ''
	) IS
		isSelected BOOLEAN;
    BEGIN
        htp.prn('<div class="formField">');
        IF placeholder IS NOT NULL THEN
            htp.prn('<label>' || placeholder || '</label>');
        ELSE
            htp.prn('<label class="hidden">_</label>');
        END IF;

        gui.apriDiv(classe => 'dropdown');
			gui.apriDiv(classe => 'dropbtn', onclick => 'apriMenu(this.parentNode)');
				htp.prn('<span class="text">' || testo || '</span>');
				htp.prn('<span class="arrow"></span>');
			gui.chiudiDiv;
			gui.apriDiv(ident => 'dropdown-content', classe => 'dropdown-content');

				FOR i IN 1..ids.count LOOP
					isSelected := FALSE;
					FOR j IN 1..parametriSelezionati.count LOOP
						IF ids(i) = parametriSelezionati(j) THEN
							isSelected := TRUE;
							EXIT;
						END IF;
					END LOOP;

					gui.apriDiv(ident => 'option');
						htp.prn('<input type="checkbox" id="' || ident || ids(i) || '" value="' || ids(i) || '"');
						IF isSelected THEN
							htp.prn(' checked');
						END IF;
						htp.prn(' onchange="updateHiddenInput(' || chr(39) || hiddenParameter || chr(39) || ', this)"/>');
						htp.prn('<label for="' || ident || ids(i) || '">' || names(i) || '</label>');
						IF isSelected THEN
						
							htp.prn('<script>updateHiddenInput(' || chr(39) || hiddenParameter || chr(39) || ', document.getElementById(' || chr(39) || ids(i) || chr(39) || '));</script>');
						END IF;
					gui.chiudiDiv();
				END LOOP;

        		gui.chiudiDiv();
    		gui.chiudiDiv();
		gui.chiudiDiv;
	END aggiungiSelezioneMultipla;

	-- Procedura per popup di errore/successo
	procedure AggiungiPopup(successo boolean, testo VARCHAR2 default 'Errore!', indirizzo varchar2 default '') IS
	begin

		if successo then 
			htp.prn('<div id="popup-message" class="message-box success">');
				htp.prn('<p>'|| testo ||'</p>');
				htp.prn('<button class="bottone-popup" onclick="nascondiPopup()">Chiudi</button>');
			htp.prn('</div>');
		else 
			if indirizzo IS NOT NULL then 
				htp.prn('<div id="popup-message" class="message-box error">');
				htp.prn('<p>'|| testo ||'</p>');
				htp.prn('<button class="bottone-popup">
				<a href="'||indirizzo||'">Torna indietro</a></button>');
			htp.prn('</div>');
			else 
				htp.prn('<div id="popup-message" class="message-box error">');
				htp.prn('<p>'|| testo ||'</p>');
				htp.prn('<button class="bottone-popup" onclick="nascondiPopup()">Chiudi</button>');
			htp.prn('</div>');
			end if; 
			
		end if;
	end AggiungiPopup;

	procedure Footer is
	BEGIN
		gui.APRIDIV(ident => 'footer');
		htp.prn('<footer>');
		gui.APRIDIV(ident => 'bottoneSinistra');
			gui.BottoneTopBar(testo => 'Contattaci'); 
			gui.BottoneTopBar(testo => 'Su di noi'); 
			gui.BottoneTopBar(testo => 'Termini di servizio'); 
			gui.BottoneTopBar(testo => 'Privacy'); 
		gui.CHIUDIDIV;
		htp.prn('</footer>');
		gui.CHIUDIDIV;
	END Footer;

	/*Form*/

	procedure aggiungiForm (classe VARCHAR2 default '', name VARCHAR2 default '', url VARCHAR2 default '', onSubmit varchar2 default '') IS
	BEGIN
		htp.prn ('<form method="GET" class="'||classe||'" name="'||name||'" action="'||url||'"" onsubmit="'||onSubmit||'">'); 
			gui.APRIDIV(classe => 'form-container'); 
	END aggiungiForm;

	procedure chiudiForm IS
	BEGIN
		gui.CHIUDIDIV; --form-container
		htp.prn ('</form>'); 
	END chiudiForm; 

procedure AggiungiInput(tipo VARCHAR2 default 'text', nome VARCHAR2, value VARCHAR2 default '', placeholder VARCHAR2 default '', 
	required BOOLEAN default false, classe VARCHAR2 default '', ident VARCHAR2 default '', pattern VARCHAR2 default '', minimo VARCHAR2 default '', 
	massimo VARCHAR2 default '', readonly boolean default False, selected boolean default false, step varchar default null) as
BEGIN
	htp.prn('<input 
		class="'||classe||'" 
		type="'||tipo||'" 
		name="'|| nome ||'" 
		placeholder="'||placeholder||'" 
		value="'||value||'"
		min="'||minimo||'"
		max="'||massimo||'"');

	if required then 
		htp.prn(' required ');
	end if;

	if ident is not null then
		htp.prn('id ="'||ident||'"');
	end if;

	if step IS NOT NULL THEN
        htp.prn(' step="'|| step ||'"');
    end if;

		if pattern is not null then
			htp.prn('pattern="'||pattern||'" ');
		end if;

		if readonly then
			htp.prn('readonly');
		end if;

	if selected then
		htp.prn('checked');
	end if;

	htp.prn('>');


	end AggiungiInput;

	procedure AggiungiLabel(target VARCHAR2, testo VARCHAR2) is
	begin
		htp.prn('<label for="'||target||'"">'||testo||' </label>');
	end AggiungiLabel;


	procedure AggiungiBottoneTabella(testo VARCHAR2 default '', classe VARCHAR2 default 'button-tab', url VARCHAR2 default '') is
	BEGIN
		htp.prn('<td><div class="button-add-container"><a href="' || url || '" class="' || classe || '">' || testo || '</a></div></td>');
	end AggiungiBottoneTabella;

	PROCEDURE BottoneAggiungi(testo VARCHAR2 DEFAULT '', classe VARCHAR2 DEFAULT 'button-add', url VARCHAR2) IS
	BEGIN
		htp.prn('<div class="button-add-container"><a href="' || url || '" class="' || classe || '">' || testo || '</a></div>');
	END BottoneAggiungi;

	procedure aggiungiIcona (classe VARCHAR2 default '') IS
	BEGIN
		htp.prn ('<i class="'||classe||'"></i>'); 
	end aggiungiIcona; 

	procedure aggiungiCampoForm (tipo VARCHAR2 default 'text', classeIcona VARCHAR2 default '',
	nome VARCHAR2, required BOOLEAN default true, ident VARCHAR2 default '', placeholder VARCHAR2 default '',
	value VARCHAR2 default '', pattern VARCHAR2 default '', minimo VARCHAR2 default '', massimo VARCHAR2 default '', readonly boolean default False, selected boolean default false, step varchar default null) IS
	begin

	if tipo = 'text'
	then
		gui.APRIDIV (classe => 'input-group input-group-icon');    

                gui.aggiungiInput(nome => nome, placeholder => placeholder, required => required, ident => ident, classe => '', value => value, pattern => pattern, minimo => minimo, massimo => massimo, readonly => readonly, selected => selected, step => step);
                gui.apriDiv (classe => 'input-icon'); 
                    gui.aggiungiIcona(classe => classeIcona); 
                gui.chiudiDiv; 

		gui.chiudiDiv; 
		else
			gui.APRIDIV (classe => 'input-group input-group-icon');     

                gui.aggiungiInput (tipo => tipo, nome => nome, placeholder => placeholder, required => required, ident => ident, classe => '', value => value, pattern => pattern, minimo => minimo, massimo => massimo, readonly => readonly, selected => selected, step => step);
                gui.apriDiv (classe => 'input-icon'); 
                    gui.aggiungiIcona(classe => classeIcona); 
                gui.chiudiDiv; 

 	gui.chiudiDiv; 
	end if;  

	end aggiungiCampoForm;	

	procedure aggiungiGruppoInput is
	BEGIN
		gui.APRIDIV(classe => 'form-row');
			gui.APRIDIV (classe => 'input-group');
	END aggiungiGruppoInput; 

	procedure chiudiGruppoInput is
	BEGIN
		gui.CHIUDIDIV; 
		gui.CHIUDIDIV; 
	END chiudiGruppoInput; 

	procedure aggiungiBottoneSubmit (value VARCHAR2 default '') is
	BEGIN
		gui.APRIDIV(classe => 'form-submit');   
			/*Nome è vuoto perchè altrimenti aggiunge 
				pure il pulsante nell'url*/
			gui.AGGIUNGIINPUT (nome => '', tipo => 'submit', value => value);
		gui.CHIUDIDIV;
	END aggiungiBottoneSubmit; 

	------------------ Aggiunto per fare delle prove per le procedure nel gruppo operazioni
	procedure apriElementoPulsanti is
	begin
		htp.prn('<td>');

	end apriElementoPulsanti;


	procedure chiudiElementoPulsanti is
	begin
		htp.prn(' </td>');
	end chiudiElementoPulsanti;

	-----------------

	procedure aCapo(volte number default 1) is
	BEGIN
		for volta in 1..volte 
		LOOP
			htp.prn('<br>');
		END LOOP;
	end aCapo;

	--Funzione del gruppo 1 per convertire una stringa in un array
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

	procedure HomePage(p_success varchar2 default ' ', cEmail VARCHAR2 default null, p_password varchar2 default null, tipo_utente varchar2 default null, p_registrazione boolean default false, idSessione varchar default '-1') is
		idSess SESSIONIDIPENDENTI.IDSESSIONE%TYPE;
		ruolo varchar(10);
		n_ruolo int;
        utentiPermission gui.STRINGARRAY;
        counterRowTest int;
		oraAttuale varchar2(10);
		nome varchar2(15);
		ora int;
	begin
		gui.apriPagina('Home', idSessione);
			if p_registrazione then --se la registrazione è andata a buon fine visualizzo il popup
				gui.aggiungiPopup (True, 'Registrazione avvenuta!'); 
				gui.acapo;
			end if;

			if p_success is null then
				gui.aggiungiIntestazione('Login', 'h1');
				gui.acapo(2);
			end if;

			if p_success = 'T' then
				gui.aggiungiPopup(false, 'Sessione scaduta o inesistente, esegui il login per continuare a utilizzare i nostri servizi');
				gui.acapo(2);
			elsif p_success = 'L' then
				gui.aggiungiPopup(false, 'Login non riuscito, Email o Password errati');
				gui.acapo(2);
			elsif p_success = 'S' then
			    ruolo:=SESSIONHANDLER.GETRUOLO(idSessione);
				nome:= SessionHandler.getUsername(idSessione);
				oraAttuale := TO_CHAR(SYSDATE, 'HH24:MI:SS');
				ora := TO_NUMBER(SUBSTR(oraAttuale, 1, 2));
				IF ora < 12 AND ora > 5 THEN
					gui.aggiungiIntestazione('Buongiorno, '||nome||'');
				ELSIF ora < 19 THEN
					gui.aggiungiIntestazione('Buon pomeriggio, '||nome||'');
				ELSE
					gui.aggiungiIntestazione('Buonasera, '||nome||'');
				END IF;
				htp.prn('<h2 style="color: black; display: flex; justify-content: center; align-items: center;">
						Nella barra in alto trovi tutte le operazioni disponibili, divise nei vari gruppi
						</h2>');
				htp.prn('<h2 style="color: black; display: flex; justify-content: center; align-items: center;">
				Qui, invece, trovi tutte le operazioni in base al tuo ruolo
				</h2>');
				htp.prn('<img class="taxi-img" src="https://i.imgur.com/7Enpiv9.png"/>');
			    gui.APRITABELLA(elementi =>gui.STRINGARRAY(' ',' ', ' ', ' '));
			    counterRowTest:=0;
			    for url in (SELECT * FROM PERMISSIONS) loop
				    utentiPermission:=gui.STRINGARRAY();
				    utentiPermission:=gui.STRINGTOARRAY(url.USERS);
				    if(ruolo  member of utentiPermission) then
				        if(counterRowTest=0) then
                            gui.AGGIUNGIRIGATABELLA();
							gui.AggiungiBottoneTabella(url.name,url=>url.PROCEDUREURL||idSessione);
							counterRowTest:=counterRowTest+1;
							gui.aggiungiElementoTabella(' ');
							gui.aggiungiElementoTabella(' ');
						elsif counterRowTest = 1 then
							gui.AggiungiBottoneTabella(url.name,url=>url.PROCEDUREURL||idSessione);
							counterRowTest:=counterRowTest+1;
						end if;
					    if(counterRowTest=2) then
                            gui.ChiudiRigaTabella();
                            counterRowTest:=0;
                        end if;
					end if;
				end loop;
			    gui.CHIUDITABELLA();
				
			elsif p_success = 'LOF' then
				gui.aggiungiPopup(false, 'Logout non riuscito, qualcosa è andato storto');
				gui.acapo(2);
			elsif p_success = 'LOS' then
				gui.aggiungiPopup(true, 'Logout riuscito, accedere di nuovo per utilizzare i nostri servizi');
				gui.acapo(2);
			end if;

			if((cEmail is null or p_password is null) and  p_success <> 'S') then
                gui.aggiungiForm(url=> costanti.URL||'gui.homePage');
					gui.AGGIUNGIINTESTAZIONE('Inserisci email e password', 'h2');
					gui.aggiungiGruppoInput;
						gui.aggiungiCampoForm('email', 'fa fa-envelope', 'cEmail', true, '', 'Email');
						--gui.AggiungiLabel('','');
						gui.aggiungiCampoForm('password', 'fa fa-key', 'p_password',true, '', 'Password');
					gui.chiudiGruppoInput;
				
					
						gui.aggiungiIntestazione(testo => '', dimensione => 'h4');
						gui.apriDiv(classe => 'row');
						gui.AGGIUNGIGRUPPOINPUT; 
							gui.AGGIUNGIINPUT (nome => 'tipo_utente', ident => 'cliente', tipo => 'radio', value => '00');
							gui.AGGIUNGILABEL (target => 'cliente', testo => 'Cliente');
							gui.AGGIUNGIINPUT (nome => 'tipo_utente', ident => 'autista', tipo => 'radio', value => '02', selected => true);
							gui.AGGIUNGILABEL (target => 'autista', testo => 'Autista');
							gui.AGGIUNGIINPUT (nome => 'tipo_utente', ident => 'operatore', tipo => 'radio', value => '01');
							gui.AGGIUNGILABEL (target => 'operatore', testo => 'Operatore');
							gui.AGGIUNGIINPUT (nome => 'tipo_utente', ident => 'manager', tipo => 'radio', value => '03');
							gui.AGGIUNGILABEL (target => 'manager', testo => 'Manager');
							gui.AGGIUNGIINPUT (nome => 'tipo_utente', ident => 'contabile', tipo => 'radio', value => '04');
							gui.AGGIUNGILABEL (target => 'contabile', testo => 'Contabile');
						gui.CHIUDIGRUPPOINPUT;  
						gui.chiudiDiv;

					gui.aggiungiIntestazione(testo => '', dimensione => 'h4');
					gui.aggiungiGruppoInput;
						gui.aggiungiBottoneSubmit('Accedi');
					gui.chiudiGruppoInput;

			gui.chiudiForm;
			gui.acapo;
				
            elsif p_success <> 'S' then
				if tipo_utente is null then -- in caso non venga scelto nessun ruolo per l'autenticazione
				    gui.reindirizza(costanti.URL||'gui.homePage?p_success=L');
				end if;

				idSess := LOGINLOGOUT.AGGIUNGISESSIONE(cEmail,p_password,tipo_utente);
				if idSess is null then
				    gui.reindirizza(costanti.URL||'gui.homePage?p_success=L');
				else

					gui.reindirizza(costanti.URL||'gui.homePage?p_success=S&idSessione='||idSess);
                end if;
            end if;

		gui.chiudiPagina();

		EXCEPTION
			WHEN OTHERS THEN
			    gui.reindirizza(costanti.URL||'gui.homePage?p_success=L');  -- errore ancora da risolvere'
	end HomePage;

	procedure LogOut(idSessione varchar2) is
	begin
		if loginlogout.terminaSessione(idSessione) THEN
			gui.Reindirizza(costanti.URL||'gui.homePage?p_success=LOS');
		else
			gui.Reindirizza(costanti.URL||'gui.homePage?p_success=LOF');
		end if;
	end LogOut;

	procedure AggiungiChart(ident varchar2, dataObject varchar2) is
	begin
		gui.apriDiv;
			htp.prn('<canvas id="'||ident||'"></canvas>');
		gui.chiudiDiv;

		htp.prn('<script>

				new Chart(document.getElementById("'||ident||'"), '||dataObject||');
				
			</script>');
	end;

end gui;
--tipo VARCHAR2 default 'text', classeIcona VARCHAR2 default '', nome VARCHAR2, required BOOLEAN default true, ident VARCHAR2 default '', placeholder VARCHAR2 default '',tipo VARCHAR2 default 'text', nome VARCHAR2, value VARCHAR2 default '', placeholder VARCHAR2 default '', pattern VARCHAR2 default '', minimo VARCHAR2 default '', massimo VARCHAR2 default '', readonly boolean default False, selected boolean default false, step varchar default null
