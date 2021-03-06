package tink.http;

import haxe.io.Bytes;
import tink.io.IdealSource;
import tink.io.Source;
import tink.io.Sink;
import tink.core.Named;
using tink.CoreApi;

typedef StructuredBody = Array<Named<BodyPart>>;

enum BodyPart {
  Value(v:String);
  File(handle:UploadedFile);
}

@:forward
abstract UploadedFile(UploadedFileBase) from UploadedFileBase to UploadedFileBase {
  static public function ofBlob(name:String, type:String, data:Bytes):UploadedFile
    return {
      fileName: name,
      mimeType: type,
      size: data.length,
      read: function():Source return data,
      saveTo: function(path:String) {
        var name = 'File sink $path';
        
        var dest:Sink = 
          #if (nodejs && !macro)
            Sink.ofNodeStream(name, js.node.Fs.createWriteStream(path))
          #elseif sys
            Sink.ofOutput(name, sys.io.File.write(path))
          #else
            null
            //#error
          #end
        ;
        return (data : IdealSource).pipeTo(dest, { end: true } ).map(function (r) return switch r {
          case AllWritten: Success(Noise);
          case SinkEnded: Failure(new Error("File $path closed unexpectedly"));
          case SinkFailed(e): Failure(e);
        });
      }
    }
}

typedef UploadedFileBase = {
  
  var fileName(default, null):String;
  var mimeType(default, null):String;
  var size(default, null):Int;
  
  function read():Source;
  function saveTo(path:String):Surprise<Noise, Error>;
}