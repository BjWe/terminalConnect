unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, CheckLst, Buttons, process, RegExpr;

type

  { TMainForm }

  TMainForm = class(TForm)
    testfreerdp3: TCheckBox;
    optSoundType: TComboBox;
    optMicrophoneType: TComboBox;
    optUseEncryption: TComboBox;
    dirMode: TComboBox;
    Image1: TImage;
    Label10: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    optUseMultimonitor: TCheckBox;
    optUseMicrophone: TCheckBox;
    optUseVECFoot: TCheckBox;
    optUseWallpaper: TCheckBox;
    optUseRemoteFX: TCheckBox;
    optUseFonts: TCheckBox;
    optUseAero: TCheckBox;
    optUseGDIHW: TCheckBox;
    smartcardreaderType: TComboBox;
    Label6: TLabel;
    domains: TComboBox;
    SpeedButton1: TSpeedButton;
    TabSheet6: TTabSheet;
    TabSheet7: TTabSheet;
    usbDeviceListRefreshBtn: TButton;
    usbDeviceList: TCheckListBox;
    generateDebugCMDBtn: TButton;
    Label4: TLabel;
    Label5: TLabel;
    debugCMD: TMemo;
    netAddrList: TListBox;
    optUseSound: TCheckBox;
    optOptions: TCheckBox;
    optPages: TPageControl;
    optUseSmartcard: TCheckBox;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    TabSheet5: TTabSheet;
    waitBar: TProgressBar;
    saveBox: TCheckBox;
    server: TComboBox;
    Label3: TLabel;
    LoginBtn: TButton;
    username: TEdit;
    password: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure generateDebugCMDBtnClick(Sender: TObject);
    procedure LoginBtnClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure optOptionsChange(Sender: TObject);
    function bestInterfaceAdress(): string;
    function generateCMD(): string;
    procedure optPagesChange(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure usbDeviceListRefreshBtnClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

const
  DEFAULT_MAINFORM_HEIGHT: integer = 310;

var
  MainForm: TMainForm;

  proc: TProcess;
  conf: TStringList;

  lastError: String;

implementation

{$R *.lfm}

function implode(sPatter : char; sArray : TStringList): string;
var
  i: integer;
  sReturn: string;
begin
  sReturn := '';
  for i := 0 to sArray.Count - 1 do
  begin
    sReturn := sReturn + sArray[I];
    if (I+1 < sArray.Count) then
    begin
      sReturn := sReturn + sPatter;
    end;
  end;
  result := sReturn;
end;

function GetIPAddressOfInterface(if_name: ansistring): ansistring;
begin
  result := '127.0.0.1'
end;

{
function GetIPAddressOfInterface(if_name: ansistring): ansistring;
var
  ifr : ifreq;
  sock : longint;
  p:pChar;

begin
  Result:='0.0.0.0';
  strncpy( ifr.ifr_ifrn.ifrn_name, pChar(if_name), IF_NAMESIZE-1 );
  ifr.ifr_ifru.ifru_addr.sa_family := AF_INET;
  sock := socket(AF_INET, SOCK_DGRAM, IPPROTO_IP);
  if ( sock >= 0 ) then begin
    if ( ioctl( sock, SIOCGIFADDR, @ifr ) >= 0 ) then begin
      p:=inet_ntoa( ifr.ifr_ifru.ifru_addr.sin_addr );
      if ( p <> nil ) then Result :=  p;
    end;
    libc.__close(sock);
  end;
end;
}

function interfaceNames(): TStringList;
var
  s: shortstring;
  f: text;
  p: LongInt;
begin
  result := TStringList.Create;

  assign(f,'/proc/net/dev');
  reset(f);
  while not eof(f) do begin
    readln(f,s);
    p:=pos(':',s);
    if ( p > 0 ) then begin
      delete(s, p, 255);
      while ( s <> '' ) and (s[1]=#32) do
      begin
        delete(s,1,1);
      end;
      result.Add(s);
    end;
  end;
  close(f);
end;


{ TMainForm }

function TMainForm.bestInterfaceAdress(): string;
  function ipVote(ip: string): integer;
  begin
    if ip = '0.0.0.0' then
      result := 1
    else if ip = '127.0.0.1' then
      result := 2
    else if Copy(ip, 1, 8) = '192.168.' then
      result := 5
    else if Copy(ip, 1, 6) = '10.16.' then
      result := 7
    else
      result := 0;
  end;

var
  i: integer;
  lastvote: integer;
  actvote: integer;

  hostnameFS: TFileStream;
  hostname: string;
  elPos: integer;
begin
  result := '';
  lastvote := 0;

  try
    hostnameFS := TFileStream.Create('/etc/hostname', fmOpenRead);
    SetLength(hostname, hostnameFS.Size);
    hostnameFS.Read(hostname[1], hostnameFS.Size);

    elPos := pos('.', hostname);
    if elPos > 0 then
    begin
      hostname := Copy(hostname, 1, elPos-1);
    end;

    //showmessage(hostname);

  finally
    hostnameFS.Free;
  end;

  if hostname <> '' then
  begin
    Result := hostname;
    exit;
  end;


  for i := 0 to netAddrList.Count -1 do
  begin
    actvote := ipVote(netAddrList.Items.Strings[i]);
    if actvote > lastvote then
    begin
      lastvote := actvote;
      result := netAddrList.Items.Strings[i];
    end;
  end;
end;

function TMainForm.generateCMD(): string;
var
  params: TStringList;
  i: integer;
  regex: TRegExpr;
begin
  result := '';

  params := TStringList.Create;
  params.Add('/u:'+username.Text);   // Benutzername
  params.Add('/p:'+password.Text);   // Passwort
  params.Add('/d:'+domains.Text);    // Domäne
  //params.Add('/workarea');           // Kein Fullscreen
  params.Add('/cert-ignore');        // Zertifikat ignorieren
  params.Add('/v:'+server.Text);     // Server
  //params.Add('/f');                  // Fullscreen

  params.Add('/client-hostname:'+bestInterfaceAdress()); //IP-Addr der Arbeitsstation mitnehmen

  if optUseRemoteFX.Checked then
    params.Add('/rfx');                // RemoteFX aktivieren

  // Fonts
  if optUseFonts.Checked then
    params.Add('+fonts')
  else
    params.Add('-fonts');

  // Aero
  if optUseAero.Checked then
    params.Add('+aero')
  else
    params.Add('-aero');

  // Hintergrundbild
  if optUseWallpaper.Checked then
    params.Add('+wallpaper')
  else
    params.Add('-wallpaper');

  if optUseGDIHW.Checked then
    params.Add('/gdi:hw');

  if optUseMultimonitor.Checked then
    params.Add('/multimon');

  case optUseEncryption.ItemIndex of
    0: begin  end; // aktuell nichts
    1: begin params.Add('/sec:rdp'); end;
    2: begin params.Add('/sec:tls'); end;
    3: begin params.Add('/sec:nla'); end;
    4: begin params.Add('/sec:ext'); end;
  end;

  // Sound
  if optUseSound.Checked then
  begin
    case optSoundType.ItemIndex of
      0: begin params.Add('/sound:sys:pulse'); end;
      1: begin params.Add('/sound:sys:alsa,format:1,quality:high'); end;
    end;
  end;

  // Microphone
  if optUseMicrophone.Checked then
  begin
    case optMicrophoneType.ItemIndex of
      0: begin params.Add('/microphone:sys:pulse'); end;
      1: begin params.Add('/microphone:sys:alsa,format:1,quality:high'); end;
    end;
  end;

  if optUseVECFoot.Checked then
  begin
    params.Add('/usb:id:05f3:00ff');
  end;

  if optUseSmartcard.Checked then
  begin
    if smartcardreadertype.ItemIndex = 0 then
      params.Add('/smartcard')
    else
      params.Add('/smartcard:cyberJack');
  end;

  case DirMode.ItemIndex of
    0: begin params.Add('/drive:hotplug,*'); end;

  end;

  regex := TRegExpr.Create;
  regex.Expression := '.* ID ([0-9a-fA-F]{4})\:([0-9a-fA-F]{4}) .*';

  for i := 0 to usbDeviceList.Items.Count - 1 do
  begin
    if usbDeviceList.Checked[i] then
    begin
      if regex.Exec(usbDeviceList.Items[i]) then
      begin
        params.Add('/usb:id,dev:'+regex.Match[1]+':'+regex.Match[2]);
      end else
      begin
        showmessage('regex not match');
      end;
    end;
  end;


  if testfreerdp3.Checked then
  begin
    result := 'nohup /opt/xfreerdp3/bin/xfreerdp '+implode(' ', params);
  end else
  begin
    result := 'nohup /usr/bin/xfreerdp '+implode(' ', params);
  end;

  params.Free;
end;

procedure TMainForm.optPagesChange(Sender: TObject);
begin

end;

procedure TMainForm.SpeedButton1Click(Sender: TObject);
begin
  showmessage(lastError);
end;

procedure TMainForm.usbDeviceListRefreshBtnClick(Sender: TObject);
var
  lsusbProc: TProcess;
begin
  lsusbProc := TProcess.Create(nil);
  lsusbProc.CommandLine := 'lsusb';
  lsusbProc.Options := lsusbProc.Options + [poWaitOnExit, poUsePipes];
  lsusbProc.Execute;
  usbDeviceList.Items.LoadFromStream(lsusbProc.Output);
  lsusbProc.Free;
end;

procedure TMainForm.LoginBtnClick(Sender: TObject);
var
  i: integer;
  buff: TStringList;
  usbTmp: String;
begin
  LoginBtn.Enabled := false;

  if saveBox.Checked then
  begin
    if conf.IndexOfName('username') >= 0 then
      conf.Values['username'] := username.Text
    else
      conf.Add('username='+username.Text);

    if conf.IndexOfName('password') >= 0 then
      conf.Values['password'] := password.Text
    else
      conf.Add('password='+password.Text);

    if conf.IndexOfName('save') >= 0 then
      conf.Values['save'] := BoolToStr(saveBox.Checked, 'true', 'false')
    else
      conf.Add('save='+BoolToStr(saveBox.Checked, 'true', 'false'));

  end;

  usbTmp := '';
  for i := 0 to usbDeviceList.Items.Count - 1 do
  begin
    if usbDeviceList.Checked[i] then
    begin

    end;
  end;


    conf.Values['rfx']                 := boolToStr(optUseRemoteFX.Checked, 'true', 'false');
    conf.Values['fonts']               := boolToStr(optUseFonts.Checked, 'true', 'false');
    conf.Values['aero']                := boolToStr(optUseAero.Checked, 'true', 'false');
    conf.Values['wallpaper']           := boolToStr(optUseWallpaper.Checked, 'true', 'false');
    conf.Values['gdihw']               := boolToStr(optUseGDIHW.Checked, 'true', 'false');
    conf.Values['multimon']            := boolToStr(optUseMultimonitor.Checked, 'true', 'false');
    conf.Values['sound']               := boolToStr(optUseSound.Checked, 'true', 'false');
    conf.Values['soundtype']           := intToStr(optsoundtype.ItemIndex);
    conf.Values['microphone']          := boolToStr(optUseMicrophone.Checked, 'true', 'false');
    conf.Values['microphonetype']      := intToStr(optMicrophoneType.ItemIndex);
    conf.Values['smartcard']           := boolToStr(optUseSmartcard.Checked, 'true', 'false');
    conf.Values['vecfootswitch']       := boolToStr(optUseVECFoot.Checked, 'true', 'false');
    conf.Values['smartcardreadertype'] := intToStr(smartcardreaderType.ItemIndex);
    conf.Values['dirmode']             := intToStr(dirmode.ItemIndex);
    conf.Values['forcesec']            := intToStr(optUseEncryption.ItemIndex);



  conf.SaveToFile(GetUserDir+'/terminalconnect.conf');

  waitBar.Visible := true;


  proc := TProcess.Create(nil);
  proc.Options := [poUsePipes];
  proc.CommandLine := generateCMD();
  proc.Execute;
  //showmessage(proc.CommandLine); exit;

  //procid := proc.ProcessID;

  for i := 0 to 6000 do
  begin
    Application.ProcessMessages;
    sleep(1);
  end;

  waitBar.Visible := false;

  if not proc.Running then
  begin
    buff := TStringList.Create;
    buff.LoadFromStream(proc.Output);
    lastError := buff.Text;
    buff.free;
    showmessage('Die Verbindung konnte nicht aufgebaut werden. Benutzername / Passwort richtig?');
    proc.Free;
    LoginBtn.Enabled := true;
  end else
  begin
    proc.Free;
    close;
  end;

end;

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  conf.Free;
end;

procedure TMainForm.generateDebugCMDBtnClick(Sender: TObject);
begin
  debugCMD.Text := generateCMD();
end;

procedure TMainForm.Button2Click(Sender: TObject);
begin

end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  interfaces: TStringList;
  i: integer;
begin
  height := DEFAULT_MAINFORM_HEIGHT;

  conf := TStringList.Create;

  if FileExists(GetUserDir+'/terminalconnect.conf') then
    conf.LoadFromFile(GetUserDir+'/terminalconnect.conf');

  usbDeviceListRefreshBtn.Click;

  if FileExists('/opt/xfreerdp3/bin/xfreerdp') then
    testfreerdp3.Enabled := true;

  if conf.IndexOfName('username') >= 0 then
    username.Text := conf.Values['username'];

  if conf.IndexOfName('password') >= 0 then
    password.Text := conf.Values['password'];

  if conf.IndexOfName('save') >= 0 then
    saveBox.Checked := conf.Values['save'] = 'true';

  if conf.IndexOfName('rfx') >= 0 then
    optUseRemoteFX.Checked := conf.Values['rfx'] = 'true';

  if conf.IndexOfName('fonts') >= 0 then
    optUseFonts.Checked := conf.Values['fonts'] = 'true';

  if conf.IndexOfName('aero') >= 0 then
    optUseAero.Checked := conf.Values['aero'] = 'true';

  if conf.IndexOfName('wallpaper') >= 0 then
    optUseWallpaper.Checked := conf.Values['wallpaper'] = 'true';

  if conf.IndexOfName('gdihw') >= 0 then
    optUseGDIHW.Checked := conf.Values['gdihw'] = 'true';

  if conf.IndexOfName('multimon') >= 0 then
    optUseMultimonitor.Checked := conf.Values['multimon'] = 'true';

  if conf.IndexOfName('sound') >= 0 then
    optUseSound.Checked := conf.Values['sound'] = 'true';

  if conf.IndexOfName('soundtype') >= 0 then
    optSoundType.ItemIndex := strtoint(conf.Values['soundtype']);

  if conf.IndexOfName('microphone') >= 0 then
    optUseMicrophone.Checked := conf.Values['microphone'] = 'true';

  if conf.IndexOfName('microphonetype') >= 0 then
    optMicrophoneType.ItemIndex := strtoint(conf.Values['microphonetype']);

  if conf.IndexOfName('vecfootswitch') >= 0 then
    optUseVECFoot.Checked := conf.Values['vecfootswitch'] = 'true';

  if conf.IndexOfName('smartcard') >= 0 then
    optUseSmartcard.Checked := conf.Values['smartcard'] = 'true';

  if conf.IndexOfName('smartcardtype') >= 0 then
    smartcardreaderType.ItemIndex := strToInt(conf.Values['smartcardreadertype']);

  if conf.IndexOfName('dirmode') >= 0 then
    dirmode.ItemIndex := strToInt(conf.Values['dirmode']);

  if conf.IndexOfName('forcesec') >= 0 then
    optUseEncryption.ItemIndex := StrToInt(conf.Values['forcesec']);

  if FileExists(ExtractFilePath(ParamStr(0))+'/servers.conf') then
    server.Items.LoadFromFile(ExtractFilePath(ParamStr(0))+'/servers.conf');

  if FileExists(GetUserDir+'/terminalconnect.servers.conf') then
    server.Items.LoadFromFile(GetUserDir+'/terminalconnect.servers.conf');


  if FileExists(ExtractFilePath(ParamStr(0))+'/domains.conf') then
    domains.Items.LoadFromFile(ExtractFilePath(ParamStr(0))+'/domains.conf');

  if FileExists(GetUserDir+'/terminalconnect.domains.conf') then
    domains.Items.LoadFromFile(GetUserDir+'/terminalconnect.domains.conf');

  server.ItemIndex := 0;
  domains.ItemIndex := 0;

  // Netzwerkadressen laden
  interfaces := interfaceNames();

  for i := 0 to interfaces.Count -1 do
  begin
    netAddrList.Items.Add(GetIPAddressOfInterface(interfaces.Strings[i]));
  end;

  interfaces.Free;
end;

procedure TMainForm.optOptionsChange(Sender: TObject);
begin
  MainForm.BorderStyle := bsSizeable;
  if optOptions.Checked then
    MainForm.Height := 680
  else
    MainForm.Height := DEFAULT_MAINFORM_HEIGHT;
  MainForm.BorderStyle := bsSingle;
  optPages.Visible := optOptions.Checked;
end;

end.

