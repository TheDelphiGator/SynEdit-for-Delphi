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
// eg. TSynEditOptions.LoadFromFile(AMySynEditObj);
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
// Will autosave to the .OPT file if AAutoSave is NOT specified or set to FALSE
// Settings can also be saved manually via method SaveToFile
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

end.
