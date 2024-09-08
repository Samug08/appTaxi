/*drop sequence  sequenceIdSessioniClienti;
drop sequence  sequenceIdSessioniDipendenti;
drop table SessioniDipendenti;
drop table SessioniClienti;*/

CREATE SEQUENCE sequenceIdSessioniClienti START WITH 1 INCREMENT BY 1 MAXVALUE 4294967295 ;
CREATE SEQUENCE sequenceIdSessioniDipendenti START WITH 1 INCREMENT BY 1 MAXVALUE 4294967295 ;

create table SessioniClienti(
  IDSessione varchar(10) NOT NULL,
  IDCliente int NOT NULL,
  inizioSessione TIMESTAMP DEFAULT SYSDATE NOT NULL,
  fineSessione TIMESTAMP DEFAULT NULL,
  CONSTRAINT pkSessioneCliente PRIMARY KEY (idSessione),
  CONSTRAINT fkSessionCliente FOREIGN KEY (IDCliente) REFERENCES Clienti (IDCLIENTE)
);

create table SessioniDipendenti(
  IDSessione varchar(10) NOT NULL,
  IDDipendente int NOT NULL,
  inizioSessione TIMESTAMP DEFAULT SYSDATE NOT NULL,
  fineSessione TIMESTAMP DEFAULT NULL,
  CONSTRAINT pkSessioneDipendente PRIMARY KEY (idSessione),
  CONSTRAINT fkSessionDipendente FOREIGN KEY (IDDipendente) REFERENCES DIPENDENTI (matricola)
);
