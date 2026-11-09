unit DIMLang;

{
Translation of the user interface. English is built in; Catalan is in the
table below (English text -> Catalan text).

_T translates a string: an exact match first, then (for messages built from
several pieces) any known pieces inside it. TranslateComponent translates the
Caption and Hint of a component and of everything it owns or contains, and
switching back to English uses the same table the other way round, so nothing
else needs to be kept.
}

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils{$IFNDEF DIMCONSOLE}, Forms, Controls, ComCtrls, TypInfo{$ENDIF};

var
 //Current language: 'en' or 'ca'
 Language: String='en';

function _T(const s: String): String;
function IsKnownLanguage(const lang: String): Boolean;
{$IFNDEF DIMCONSOLE}
procedure TranslateComponent(C: TComponent);
procedure TranslateAllForms;
{$ENDIF}

implementation

const
 Pairs: array[0..386,0..1] of String = (
  ('  Application Styling','  Aparença de l''aplicació'),
  ('  Columns','  Columnes'),
  ('  DFS Validation','  Validació DFS'),
  ('  DOS Plus/DOS','  DOS Plus/DOS'),
  ('  Disc Filing System','  Disc Filing System'),
  ('  Image Size','  Mida de la imatge'),
  ('  Miscellaneous','  Altres'),
  ('  Options','  Opcions'),
  ('  Side 0 Details','  Detalls de la cara 0'),
  ('  Side 2 Details','  Detalls de la cara 2'),
  ('  Side Details','  Detalls de la cara'),
  ('  System','  Sistema'),
  ('  Track Order (ADFS L and Acorn FS)','  Ordre de les pistes (ADFS L i Acorn FS)'),
  ('  Tracks','  Pistes'),
  (' DOS partitions. Which one do you want to work with?',' particions DOS. Amb quina vols treballar?'),
  (' can open.',' pugui obrir.'),
  (' file(s) or folder(s) whose names start with a dot:',' fitxer(s) o carpeta(es) amb noms que comencen per un punt:'),
  (' files?',' fitxers?'),
  ('" - error unknown','" - error desconegut'),
  ('" - image full','" - la imatge és plena'),
  ('" - map full','" - el mapa és ple'),
  ('" - nothing to write','" - no hi ha res per escriure'),
  ('" - unknown error','" - error desconegut'),
  ('" already exists','" ja existeix'),
  ('" already exists in directory','" ja existeix al directori'),
  ('" already exists in image','" ja existeix a la imatge'),
  ('" already exists in the directory "','" ja existeix al directori "'),
  ('" has not been recognised as a valid disc image that ','" no s''ha reconegut com una imatge de disc vàlida que '),
  ('" is not a directory','" no és un directori'),
  ('" to the same directory','" al mateix directori'),
  ('" when adding "','" en afegir "'),
  ('". Overwrite?','". El vols sobreescriure?'),
  ('&About...','&Quant a...'),
  ('&Add File(s)...','&Afegeix fitxer(s)...'),
  ('&Add Partition...','&Afegeix una partició...'),
  ('&Change Interleave...','&Canvia l''entrellaçat...'),
  ('&Close Image','&Tanca la imatge'),
  ('&Delete ','&Esborra '),
  ('&Delete File','&Esborra el fitxer'),
  ('&Delete File(s)','&Esborra fitxer(s)'),
  ('&Delete Partition','&Esborra la partició'),
  ('&Edit Password File...','&Edita el fitxer de contrasenyes...'),
  ('&Extract ','&Extreu '),
  ('&Extract File','&Extreu el fitxer'),
  ('&Extract File(s)...','&Extreu fitxer(s)...'),
  ('&File Details','&Detalls del fitxer'),
  ('&Files','&Fitxers'),
  ('&Image','&Imatge'),
  ('&Image Details','&Detalls de la imatge'),
  ('&Image Details...','&Detalls de la imatge...'),
  ('&Multi CSV Output...','Sortida CSV &múltiple...'),
  ('&New Directory','&Directori nou'),
  ('&New Image...','Imatge &nova...'),
  ('&Open File Viewer','&Obre el visor de fitxers'),
  ('&Open Image...','&Obre una imatge...'),
  ('&Partition','&Partició'),
  ('&Preferences','&Preferències'),
  ('&Refresh Image','&Refresca la imatge'),
  ('&Rename ','&Canvia el nom '),
  ('&Rename File','&Canvia el nom del fitxer'),
  ('&Repair Broken ADFS Directories...','&Repara directoris ADFS trencats...'),
  ('&Save ','&Desa '),
  ('&Save Image...','&Desa la imatge...'),
  ('&Save Partition As...','&Desa la partició com a...'),
  ('&Tool Bars','&Barres d''eines'),
  ('&Tools','&Eines'),
  ('&View File Contents...','&Mostra el contingut del fitxer...'),
  ('Abort','Avorta'),
  ('About','Quant a'),
  ('About Disc Image Manager','Quant al Disc Image Manager'),
  ('Acorn FS User Account Editor','Editor de comptes d''usuari d''Acorn FS'),
  ('Add','Afegeix'),
  ('Add &Password File','Afegeix un fitxer de &contrasenyes'),
  ('Add File(s)','Afegeix fitxer(s)'),
  ('Add Implied Attributes (DFS/CFS/RFS)','Afegeix els atributs implícits (DFS/CFS/RFS)'),
  ('Add Partition','Afegeix una partició'),
  ('Add Password File','Afegeix un fitxer de contrasenyes'),
  ('Add a file, or import an image, to image','Afegeix un fitxer, o importa una imatge, a la imatge'),
  ('Add a new or existing side','Afegeix una cara nova o existent'),
  ('Add a new partition','Afegeix una partició nova'),
  ('Adding ','Afegint '),
  ('Address','Adreça'),
  ('Allow blank filenames','Permet noms de fitxer en blanc'),
  ('Allow files goes over disc edge','Permet fitxers que passin de la vora del disc'),
  ('Allow zero sectors','Permet zero sectors'),
  ('Append filetypes on export','Afegeix el tipus de fitxer en exportar'),
  ('Archive','Arxiu'),
  ('Attributes','Atributs'),
  ('Attributes - Miscallaenous','Atributs - altres'),
  ('Attributes - Other Access','Atributs - altres accessos'),
  ('Attributes - Owner Access','Atributs - accés del propietari'),
  ('Attributes - Public Access','Atributs - accés públic'),
  ('Automatic (recommended)','Automàtic (recomanat)'),
  ('BBC BASIC File','Fitxer BBC BASIC'),
  ('Big','Gran'),
  ('Boot Option','Opció d''arrencada'),
  ('CRC32','CRC32'),
  ('CSV Preferences','Preferències de CSV'),
  ('Cancel','Cancel·la'),
  ('Cannot add to multiple selection','No es pot afegir a una selecció múltiple'),
  ('Cannot create a directory on this platform','En aquest sistema no es poden crear directoris'),
  ('Cannot find directory "','No es troba el directori "'),
  ('Cannot find parent when adding directory "','No es troba el pare en afegir el directori "'),
  ('Cannot move "','No es pot moure "'),
  ('Cannot rename file/directory - "','No es pot canviar el nom del fitxer/directori - "'),
  ('Catalogue full when adding "','Catàleg ple en afegir "'),
  ('Catalogue full when writing "','Catàleg ple en escriure "'),
  ('Change Interleave','Canvia l''entrellaçat'),
  ('Change Interleave Method','Canvia el mètode d''entrellaçat'),
  ('Click to copy to clipboard','Fes clic per copiar al porta-retalls'),
  ('Click to edit','Fes clic per editar'),
  ('Close Image File','Tanca el fitxer d''imatge'),
  ('Compress UEF images','Comprimeix les imatges UEF'),
  ('Confirmation','Confirmació'),
  ('Convert','Converteix'),
  ('Could not add directory - image full','No s''ha pogut afegir el directori: la imatge és plena'),
  ('Could not add file "','No s''ha pogut afegir el fitxer "'),
  ('Could not create directory "','No s''ha pogut crear el directori "'),
  ('Could not download file "','No s''ha pogut extreure el fitxer "'),
  ('Could not extend parent directory - image full','No s''ha pogut ampliar el directori pare: la imatge és plena'),
  ('Could not extend parent directory - no free fragments','No s''ha pogut ampliar el directori pare: no hi ha fragments lliures'),
  ('Could not extend parent directory when adding "','No s''ha pogut ampliar el directori pare en afegir "'),
  ('Could not extend parent directory when writing "','No s''ha pogut ampliar el directori pare en escriure "'),
  ('Could not find source file "','No es troba el fitxer d''origen "'),
  ('Could not load "','No s''ha pogut carregar "'),
  ('Could not locate directory "','No es troba el directori "'),
  ('Could not write directory "','No s''ha pogut escriure el directori "'),
  ('Could not write file "','No s''ha pogut escriure el fitxer "'),
  ('Create','Crea'),
  ('Create *.dsc files with new ADFS HDD','Crea fitxers *.dsc amb els discs durs ADFS nous'),
  ('Create *.inf files on download','Crea fitxers *.inf en extreure'),
  ('Create ADFS Hard Drive','Crea un disc dur ADFS'),
  ('Create Amiga Hard Drive','Crea un disc dur Amiga'),
  ('Create Blank Image','Crea una imatge en blanc'),
  ('Create DOS Hard Drive','Crea un disc dur DOS'),
  ('Create password file','Crea el fitxer de contrasenyes'),
  ('Current Interleave Method','Mètode d''entrellaçat actual'),
  ('Delete','Esborra'),
  ('Delete ','Esborra '),
  ('Delete File(s)','Esborra fitxer(s)'),
  ('Delete Partition','Esborra la partició'),
  ('Deleted','Esborrat'),
  ('Deleting ','Esborrant '),
  ('Destination directory does not exist','El directori de destinació no existeix'),
  ('Destination directory does not exist when writing "','El directori de destinació no existeix en escriure "'),
  ('Directory','Directori'),
  ('Directory "','Directori "'),
  ('Directory Title','Títol del directori'),
  ('Directory Type','Tipus de directori'),
  ('Directory:','Directori:'),
  ('Disc (volume) name, up to 11 characters:','Nom del disc (volum), fins a 11 caràcters:'),
  ('Disc Image Details','Detalls de la imatge de disc'),
  ('Disc Name','Nom del disc'),
  ('Disc Size','Mida del disc'),
  ('Disc Title(s)','Títol(s) del disc'),
  ('Do you want to delete them? Nothing is written to the image ','Els vols esborrar? No s''escriu res a la imatge '),
  ('Double Sided','Doble cara'),
  ('Download File(s)','Extreu fitxer(s)'),
  ('Duplicate &File','Duplica el &fitxer'),
  ('Duplicate File','Duplica el fitxer'),
  ('Edit Password File','Edita el fitxer de contrasenyes'),
  ('Error','Error'),
  ('Error Log','Registre d''errors'),
  ('Error when adding file "','Error en afegir el fitxer "'),
  ('Execute','Execució'),
  ('Execution Address','Adreça d''execució'),
  ('Extracting ','Extraient '),
  ('FAT Type','Tipus de FAT'),
  ('Failed to add a side to the current image.','No s''ha pogut afegir una cara a la imatge actual.'),
  ('Failed to add a side/partition to the current image.','No s''ha pogut afegir una cara/partició a la imatge actual.'),
  ('Failed to create ','No s''ha pogut crear '),
  ('Failed to create Passwords file','No s''ha pogut crear el fitxer de contrasenyes'),
  ('Failed to create a password file','No s''ha pogut crear un fitxer de contrasenyes'),
  ('Failed to create image','No s''ha pogut crear la imatge'),
  ('Failed to defrag','No s''ha pogut desfragmentar'),
  ('Failed to open file stream "','No s''ha pogut obrir el fitxer "'),
  ('Failed to read ','No s''ha pogut llegir '),
  ('Failed to read file "','No s''ha pogut llegir el fitxer "'),
  ('Failed to read inf file "','No s''ha pogut llegir el fitxer inf "'),
  ('Failed to rename file/directory','No s''ha pogut canviar el nom del fitxer/directori'),
  ('Failed to write file stream "','No s''ha pogut escriure el fitxer "'),
  ('Failed when ','Error en '),
  ('Failed when creating directory ','Error en crear el directori '),
  ('File "','Fitxer "'),
  ('File &Viewer','&Visor de fitxers'),
  ('File Details','Detalls del fitxer'),
  ('File Search','Cerca de fitxers'),
  ('File/directory does not exist','El fitxer/directori no existeix'),
  ('Filename','Nom del fitxer'),
  ('Filename:','Nom del fitxer:'),
  ('Files','Fitxers'),
  ('Filetype','Tipus de fitxer'),
  ('Filetype:','Tipus de fitxer:'),
  ('Font Size:','Mida de la lletra:'),
  ('Format','Format'),
  ('Formatting...','Formatant...'),
  ('Free','Lliure'),
  ('Free Space','Espai lliure'),
  ('Free Space Map','Mapa d''espai lliure'),
  ('Hard Disc Capacity:','Capacitat del disc dur:'),
  ('Hex Dump','Bolcat hexadecimal'),
  ('Hidden','Ocult'),
  ('ISO Specific Attributes','Atributs específics d''ISO'),
  ('Ignore','Ignora'),
  ('Image','Imatge'),
  ('Image Contents','Contingut de la imatge'),
  ('Image Format','Format de la imatge'),
  ('Image Report','Informe de la imatge'),
  ('Image Viewer','Visor d''imatges'),
  ('Import','Importa'),
  ('Include Directories','Inclou els directoris'),
  ('Include Filename','Inclou el nom del fitxer'),
  ('Include Image Report','Inclou l''informe de la imatge'),
  ('Information','Informació'),
  ('Initialising...','Inicialitzant...'),
  ('Interleave','Entrellaçat'),
  ('Interleave Type','Tipus d''entrellaçat'),
  ('Interleaved (0,80,1,81,2,82,...)','Entrellaçat (0,80,1,81,2,82,...)'),
  ('Invalid Partition Selected','Partició seleccionada no vàlida'),
  ('Invalid partition selected','Partició seleccionada no vàlida'),
  ('Jump To:','Salta a:'),
  ('Keep','Conserva'),
  ('Keep DOS image extension on save','Conserva l''extensió de la imatge DOS en desar'),
  ('Legend','Llegenda'),
  ('Length','Mida'),
  ('Load Address','Adreça de càrrega'),
  ('Location','Ubicació'),
  ('Locked','Bloquejat'),
  ('Map Type','Tipus de mapa'),
  ('Move Down A Line','Baixa una línia'),
  ('Move Down A Page','Baixa una pàgina'),
  ('Move To Bottom','Ves al final'),
  ('Move To Top','Ves al principi'),
  ('Move Up A Line','Puja una línia'),
  ('Move Up A Page','Puja una pàgina'),
  ('Moving ','Movent '),
  ('Multi CSV Output','Sortida CSV múltiple'),
  ('Multiplexed (0,2,4,...1,3,5,...)','Multiplexat (0,2,4,...1,3,5,...)'),
  ('Native OS','Del sistema'),
  ('New','Nou'),
  ('New Directory','Directori nou'),
  ('New Image','Imatge nova'),
  ('New Interleave Method','Mètode d''entrellaçat nou'),
  ('No','No'),
  ('No Tile','Sense mosaic'),
  ('No destination directory selected','No s''ha seleccionat cap directori de destinació'),
  ('No free space to perform a defrag','No hi ha prou espai lliure per desfragmentar'),
  ('No long filenames on DOS images','Sense noms llargs a les imatges DOS'),
  ('No objects in catalogue','No hi ha objectes al catàleg'),
  ('No, just add','No, només afegeix'),
  ('Not possible on this system','No és possible en aquest sistema'),
  ('Number of results found: ','Resultats trobats: '),
  ('Number of results found: 0','Resultats trobats: 0'),
  ('OK','D''acord'),
  ('Old','Antic'),
  ('Open','Obre'),
  ('Open &File Search','Obre la &cerca de fitxers'),
  ('Open DOS partitions on ADFS','Obre les particions DOS dins d''ADFS'),
  ('Open Existing Image','Obre una imatge existent'),
  ('Open File Search Window','Obre la finestra de cerca de fitxers'),
  ('Parent','Pare'),
  ('Partition','Partició'),
  ('Partition ','Partició '),
  ('Partition Size','Mida de la partició'),
  ('Password','Contrasenya'),
  ('Perform a &Defrag (Compact)','Fes una &desfragmentació (compacta)'),
  ('Perform a Defrag (Compact)','Fes una desfragmentació (compacta)'),
  ('Please wait, working...','Espera, s''està treballant...'),
  ('Preferences','Preferències'),
  ('Preparing ','Preparant '),
  ('Preparing report','Preparant l''informe'),
  ('Preparing report...','Preparant l''informe...'),
  ('Preparing to defrag','Preparant la desfragmentació'),
  ('Private','Privat'),
  ('RISC OS 5 graphics designed by Richard Hallas','Gràfics de RISC OS 5 dissenyats per Richard Hallas'),
  ('RISC OS Filetypes','Tipus de fitxer de RISC OS'),
  ('Read','Lectura'),
  ('Read Only','Només lectura'),
  ('Reading ','Llegint '),
  ('Reading in the newly created image','Llegint la imatge nova'),
  ('Refresh Image (read it again, keeping any changes)','Refresca la imatge (la torna a llegir, sense perdre els canvis)'),
  ('Rename File','Canvia el nom del fitxer'),
  ('Renaming unsupported in this format','Aquest format no permet canviar noms'),
  ('Repair ADFS Broken Directories','Repara directoris ADFS trencats'),
  ('Save &Details As CSV...','Desa els &detalls com a CSV...'),
  ('Save File Details as CSV','Desa els detalls dels fitxers com a CSV'),
  ('Save Image As','Desa la imatge com a'),
  ('Save Partition As','Desa la partició com a'),
  ('Save as Text File','Desa com a fitxer de text'),
  ('Save as text file','Desa com a fitxer de text'),
  ('Scan sub-directories on open','Llegeix els subdirectoris en obrir'),
  ('Search','Cerca'),
  ('Select DOS Partition','Selecciona la partició DOS'),
  ('Select DOS Partition...','Selecciona la partició DOS...'),
  ('Select which files to import','Selecciona quins fitxers vols importar'),
  ('Sequential (0,1,2,...80,81,82,...)','Seqüencial (0,1,2,...80,81,82,...)'),
  ('Show File Viewer','Mostra el visor de fitxers'),
  ('Show Image &Report...','Mostra l''&informe de la imatge...'),
  ('Show Image Report','Mostra l''informe de la imatge'),
  ('Single Sided','Una cara'),
  ('Sprite Viewer','Visor de sprites'),
  ('System','Sistema'),
  ('Text File','Fitxer de text'),
  ('The current open image is not suitable for this archive. ','La imatge oberta no és adequada per a aquest arxiu. '),
  ('The file has been detected as an image.Would you like to import the contents or add to the open image?','S''ha detectat que el fitxer és una imatge. Vols importar-ne el contingut o afegir-lo a la imatge oberta?'),
  ('These are normally created by macOS (for example, when the ','Normalment els crea el macOS (per exemple, quan la '),
  ('They only take up space on the disc.','Només ocupen espai al disc.'),
  ('This has been detected as a Spark archive. ','S''ha detectat que és un arxiu Spark. '),
  ('This image contains ','Aquesta imatge conté '),
  ('This image does not have a partition table.','Aquesta imatge no té taula de particions.'),
  ('This image has only one DOS partition:','Aquesta imatge només té una partició DOS:'),
  ('TimeStamp','Data i hora'),
  ('Timestamp','Data i hora'),
  ('Title','Títol'),
  ('Tools','Eines'),
  ('Unformatted','Sense formatar'),
  ('Username','Usuari'),
  ('Version ','Versió '),
  ('Vie&w','&Visualitza'),
  ('View/Edit Image Details','Mostra/edita els detalls de la imatge'),
  ('Would you like to continue regardless?','Vols continuar igualment?'),
  ('Would you like to continue?','Vols continuar?'),
  ('Would you like to uncompress and add the contents?','Vols descomprimir-lo i afegir-ne el contingut?'),
  ('Write','Escriptura'),
  ('Write debugging information (slow)','Escriu informació de depuració (lent)'),
  ('XOR key:','Clau XOR:'),
  ('Yes','Sí'),
  ('You have unsaved changes. Do you wish to continue?','Tens canvis sense desar. Vols continuar?'),
  ('file until you save it.','fins que la desis.'),
  ('image is mounted in the Finder) and are not needed by DOS. ','imatge es munta al Finder) i el DOS no els necessita. '),
  ('with additions by Greg Cook and Phil Pemberton','amb aportacions de Greg Cook i Phil Pemberton'),
  ('written by Gerald J Holdsworth','escrit per Gerald J Holdsworth'),
  ('  ADFS Partition Details','  Detalls de la partició ADFS'),
  ('  Acorn FS Partition Details','  Detalls de la partició Acorn FS'),
  ('  DOS Partition Details','  Detalls de la partició DOS'),
  (' of ',' de '),
  ('&Delete Application','&Esborra l''aplicació'),
  ('&Delete Directory','&Esborra el directori'),
  ('&Delete File ','&Esborra el fitxer'),
  ('&Delete Files','&Esborra els fitxers'),
  ('&Delete Side','&Esborra la cara'),
  ('&Extract Application...','&Extreu l''aplicació...'),
  ('&Extract Directory...','&Extreu el directori...'),
  ('&Extract File ...','&Extreu el fitxer...'),
  ('&Extract Files...','&Extreu els fitxers...'),
  ('&Rename Application','&Canvia el nom de l''aplicació'),
  ('&Rename Directory','&Canvia el nom del directori'),
  ('&Rename File ','&Canvia el nom del fitxer'),
  ('&Rename Files','&Canvia el nom dels fitxers'),
  ('&Save Side As...','&Desa la cara com a...'),
  ('Application','Aplicació'),
  ('Delete Application','Esborra l''aplicació'),
  ('Delete Directory','Esborra el directori'),
  ('Delete File ','Esborra el fitxer'),
  ('Delete Files','Esborra els fitxers'),
  ('Delete Side','Esborra la cara'),
  ('Extract Application','Extreu l''aplicació'),
  ('Extract Directory','Extreu el directori'),
  ('Extract File ','Extreu el fitxer'),
  ('Extract Files','Extreu els fitxers'),
  ('Rename Application','Canvia el nom de l''aplicació'),
  ('Rename Directory','Canvia el nom del directori'),
  ('Rename File ','Canvia el nom del fitxer'),
  ('Rename Files','Canvia el nom dels fitxers'),
  ('&Sort Files','&Ordena els fitxers'),
  ('Sort Files','Ordena els fitxers'),
  ('By name (A to Z)','Per nom (de la A a la Z)'),
  ('By name (Z to A)','Per nom (de la Z a la A)'),
  ('By date (oldest first)','Per data (els més antics primer)'),
  ('By date (newest first)','Per data (els més nous primer)'),
  ('By size (smallest first)','Per mida (els més petits primer)'),
  ('By size (largest first)','Per mida (els més grans primer)'),
  ('Sort When Defragging','Ordena en desfragmentar'),
  ('Do not sort','No ordenis'),
  ('Sorting files','Ordenant els fitxers'),
  ('Nothing to sort: the files are already in that order','No cal ordenar: els fitxers ja estan en aquest ordre'),
  ('Name','Nom'),
  ('Attr.','Atrib.'),
  ('Size','Mida'),
  ('Modified','Modificat'),
  ('Change &Attributes...','Canvia els &atributs...'),
  ('Change Attributes','Canvia els atributs'),
  ('Read only','Només lectura'),
  ('Also change everything inside the selected folders','Canvia també tot el que hi ha dins de les carpetes seleccionades'),
  ('The attributes of system files can not be changed, so that the disc still boots','Els atributs dels fitxers de sistema no es poden canviar, perquè el disc continuï arrencant'),
  ('System files (shown in red) are left as they are.','Els fitxers de sistema (en vermell) es deixen com estan.'),
  ('Save Side As','Desa la cara com a')
 );

var
 ToCa, ToEn: TStringList;     //Exact matches
 Pieces    : array of Integer;//Entries used for pieces of messages, longest first

procedure BuildTables;
var
 i, j, k: Integer;
begin
 if ToCa<>nil then exit;
 ToCa:=TStringList.Create;
 ToCa.CaseSensitive:=True;
 ToCa.Sorted:=True;
 ToCa.Duplicates:=dupIgnore;
 ToEn:=TStringList.Create;
 ToEn.CaseSensitive:=True;
 ToEn.Sorted:=True;
 ToEn.Duplicates:=dupIgnore;
 for i:=Low(Pairs) to High(Pairs) do
 begin
  ToCa.AddObject(Pairs[i,0],TObject(PtrInt(i)));
  ToEn.AddObject(Pairs[i,1],TObject(PtrInt(i)));
 end;
 //Pieces: anything starting or ending with a space or a quote, or that has a
 //quote in it, longest first
 SetLength(Pieces,0);
 for i:=Low(Pairs) to High(Pairs) do
  if(Length(Pairs[i,0])>=6)
  and((Pairs[i,0][1] in [' ','"'])or(Pairs[i,0][Length(Pairs[i,0])] in [' ','"'])
   or(Pos('"',Pairs[i,0])>0))then
  begin
   k:=Length(Pieces);
   SetLength(Pieces,k+1);
   j:=k;
   while(j>0)and(Length(Pairs[Pieces[j-1],0])<Length(Pairs[i,0]))do
   begin
    Pieces[j]:=Pieces[j-1];
    dec(j);
   end;
   Pieces[j]:=i;
  end;
end;

function IsKnownLanguage(const lang: String): Boolean;
begin
 Result:=(lang='en')or(lang='ca');
end;

//Exact match only, in whichever direction the current language needs
function Exact(const s: String;var r: String): Boolean;
var
 i: Integer;
begin
 BuildTables;
 Result:=False;
 if Language='ca' then
 begin
  if ToCa.Find(s,i) then
  begin
   r:=Pairs[PtrInt(ToCa.Objects[i]),1];
   Result:=True;
  end;
 end
 else
  if ToEn.Find(s,i) then
  begin
   r:=Pairs[PtrInt(ToEn.Objects[i]),0];
   Result:=True;
  end;
end;

function _T(const s: String): String;
var
 i: Integer;
begin
 Result:=s;
 if(Language<>'ca')or(s='')then exit;
 if Exact(s,Result) then exit;
 //Not a whole match: translate any known pieces of it
 for i:=0 to Length(Pieces)-1 do
  if Pos(Pairs[Pieces[i],0],Result)>0 then
   Result:=StringReplace(Result,Pairs[Pieces[i],0],Pairs[Pieces[i],1],[rfReplaceAll]);
end;

{$IFNDEF DIMCONSOLE}
procedure TranslateProp(C: TObject;const prop: String);
var
 v, r: String;
begin
 if not IsPublishedProp(C,prop) then exit;
 if not(PropType(C,prop) in [tkSString,tkLString,tkAString,tkUString,tkWString])then exit;
 v:=GetStrProp(C,prop);
 r:=v;
 if(v<>'')and(Exact(v,r))and(r<>v)then SetStrProp(C,prop,r);
end;

procedure TranslateComponent(C: TComponent);
var
 i: Integer;
 r: String;
begin
 if C=nil then exit;
 TranslateProp(C,'Caption');
 TranslateProp(C,'Hint');
 //Status bar panels
 if C is TStatusBar then
  for i:=0 to TStatusBar(C).Panels.Count-1 do
  begin
   r:=TStatusBar(C).Panels[i].Text;
   if Exact(TStatusBar(C).Panels[i].Text,r) then TStatusBar(C).Panels[i].Text:=r;
  end;
 //Everything it owns
 for i:=0 to C.ComponentCount-1 do TranslateComponent(C.Components[i]);
 //And everything inside it that it does not own
 if C is TWinControl then
  for i:=0 to TWinControl(C).ControlCount-1 do
   if TWinControl(C).Controls[i].Owner<>C then
    TranslateComponent(TWinControl(C).Controls[i]);
end;

procedure TranslateAllForms;
var
 i: Integer;
begin
 for i:=0 to Screen.FormCount-1 do TranslateComponent(Screen.Forms[i]);
end;
{$ENDIF}

finalization
 ToCa.Free;
 ToEn.Free;
end.
