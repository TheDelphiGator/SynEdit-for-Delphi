unit MW_SynEditUtils;
interface

// =================================================================================================
// Mageware RAD Utilities
// Magetech (PTY) Ltd.
// Mike Heydon JUL 2016
//
// SynEditUtils
// ------------
// Enhancements and helper classes for SynEdit components.
// SynEdit version used v 1.32.1 2012/19/09 10:50:00 CodehunterWorks Exp
//
// TSynEditOptionsConfig Class
// ---------------------------
// Documentation of how to load and save Editor options in SynEdit is sorely lacking on the web.
// Needed to dig into code to find out how the mechanism worked.
// This class is a nice and simple way to manage this functionality without having to dig into
// the code each time to remeber how to do it.
// All methods are static and can be called without creating and instance of the class.
// eg. TSynEditOptionsConfig.LoadFromFile(AMySynEditObj);
//
// TSynEditKeyUtils Class
// ----------------------
// Utilities to assist in Keytroke processing and information text.
// All methods are static and can be called without creating and instance of the class.
// eg. TSynEditKeyUtils.GetKeystrokesHelp(AMySynEditObj,ATextList);
//
// Code is for Delphi 2010 and upward.
// Multi Platform additions need to be added for Free Pascal, Lazarus, Linux etc.
// =================================================================================================

uses Classes, SysUtils, SynEdit, SynEditOptionsDialog;

type
    // ================================================================================
    // Class with static methods to facilitate loading, editing and saving SynEdit
    // Options from and to .opt file. Method Edit wil automatically save to the .opt
    // file when closed unless parameter "AAutoSave=false" in which case the use will
    // use the SaveToFile method.
    // ================================================================================

    TSynEditOptionsConfig = class(TObject)
    public
      class procedure LoadFromFile(ASynEdit : TSynEdit);
      class procedure SaveToFile(ASynEdit : TSynEdit);
      class procedure DoEditConfig(ASynEdit : TSynEdit; AAutoSave : boolean = true);
    end;

    // ================================================================================
    // Class with static methods to facilitate processing and getting readable text
    // information about SynEdit Keystrokes.
    // ================================================================================

    TSynEditKeyUtils = class(TObject)
    public
      class procedure GetKeystrokesHelp(ASynEdit : TSynEdit; AList : TStrings);
      class function GetKeyShortcut(ASynEdit : TSynEdit; AKeyValueEC : integer) : string;
    end;

// -------------------------------------------------------------------------------------------------
implementation

{$REGION 'TSynEditOptionsConfig Class'}

// ========================================================================================
// Read and load editor settings from .OPT file and assign to passed TSynEdit component
// Options config filename will be in same dir as EXE and called <ExeName>.opt
// ========================================================================================

class procedure TSynEditOptionsConfig.LoadFromFile(ASynEdit : TSynEdit);
var sOptFile : string;
    oOpt : TSynEditorOptionsContainer;
    oStream : TFileStream;
begin
  sOptFile := ChangeFileExt(ParamStr(0),'.opt');
  oOpt := TSynEditorOptionsContainer.Create(nil);

  try
    oStream := TFileStream.Create(sOptFile,fmOpenRead);
    oStream.ReadComponent(oOpt);
    oOpt.AssignTo(ASynEdit);
  except
    // If file does not exist or error in format while loading
    // then ignore the error and the TSynEdit component will
    // have the default Option properties.
  end;

  FreeAndNil(oStream);
  FreeAndNil(oOpt);
end;

// ========================================================================================
// Save the current editor settings to .OPT file from passed TSynEdit component
// Options config filename will be in same dir as EXE and called <ExeName>.opt
// ========================================================================================

class procedure TSynEditOptionsConfig.SaveToFile(ASynEdit : TSynEdit);
var sOptFile : string;
    oOpt : TSynEditorOptionsContainer;
    oStream : TFileStream;
begin
  sOptFile := ChangeFileExt(ParamStr(0),'.opt');
  oOpt := TSynEditorOptionsContainer.Create(nil);
  oOpt.Assign(ASynEdit);
  oStream := TFileStream.Create(sOptFile,fmCreate);

  try
    oStream.WriteComponent(oOpt);
  finally
    FreeAndNil(oStream);
    FreeAndNil(oOpt);
  end;
end;

// ==============================================================================
// Edit the Options config of the passed TSynEdit component in a dialog form.
// Will autosave to the .OPT file if AAutoSave is NOT specified or set to TRUE
// If set to FALSE then no save occurs and the user can save manually via 
// method SaveToFile
// ==============================================================================

class procedure TSynEditOptionsConfig.DoEditConfig(ASynEdit : TSynEdit;
                                                   AAutoSave : boolean = true);
var oOptDlg : TSynEditOptionsDialog;
    oOpt : TSynEditorOptionsContainer;
begin
  oOptDlg := TSynEditOptionsDialog.Create(nil);
  oOpt := TSynEditorOptionsContainer.Create(nil);
  oOpt.Assign(ASynEdit);

  try
    if oOptDlg.Execute(oOpt) then begin
      oOpt.AssignTo(ASynEdit);
      if AAutoSave then SaveToFile(ASynEdit);
    end;
  finally
    FreeAndNil(oOpt);
    FreeAndNil(oOptDlg);
  end;
end;

{$ENDREGION}

{$REGION 'TSynEditKeyUtils Class'}

// =======================================================
// Load keystroke help text into a TStrings object.
// Each line is a key.value pair seperated by "="
// eg. "Delete Last Word=Ctrl+BkSp"
// =======================================================

class procedure TSynEditKeyUtils.GetKeystrokesHelp(ASynEdit : TSynEdit; AList : TStrings);
var i,ii,iPos,iLen : integer;
    sText,sKey,sName : string;
begin
  AList.Clear;
  AList.BeginUpdate;

  try
    for i := 0 to ASynEdit.Keystrokes.Count - 1 do begin
      sText := ASynEdit.Keystrokes.Items[i].DisplayName;
      iPos := pos('-',sText);
      sName := trim(copy(sText,iPos + 1));
      sKey := trim(copy(sText,3,iPos - 3));
      // Expand "Sel" to "Select"
      if pos('Select',sKey) = 0 then sKey := StringReplace(sKey,'Sel','Select',[rfReplaceAll]);
      // Break into whole words
      iLen := length(sKey);
      for ii := iLen downto 2 do if sKey[ii] = Upcase(sKey[ii]) then Insert(' ',sKey,ii);
      AList.Add(sKey + '=' + sName);
    end;
  finally
    AList.EndUpdate;
  end;
end;


// ==========================================================================================
// Return the shortcut Key Description of a passed Key Command as specified as constants
// in SynEdit unit SysEditKeyCmds.
// eg. TSynEditKeyUtils.GetKeyShortcut(MySynEdit,ecSelWordRight);
//     could return "Shift+Ctrl+Right"
// Will return NULL string if key command is NOT assigned.
// ==========================================================================================

class function TSynEditKeyUtils.GetKeyShortcut(ASynEdit : TSynEdit; AKeyValueEC : integer) : string;
var sResult,sText : string;
    iIdx,iPos : integer;
begin
  sResult := '';
  iIdx := ASynEdit.Keystrokes.FindCommand(AKeyValueEC);

  if iIdx >= 0 then begin
    sText := ASynEdit.Keystrokes.Items[iIdx].DisplayName;
    iPos := pos('-',sText);
    sResult := trim(copy(sText,iPos + 1));
  end;

  Result := sResult;
end;

{$ENDREGION}
end.
