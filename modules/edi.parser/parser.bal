import ballerina/regex;

const string UNA = "UNA";
const string UNB = "UNB";

// UNA:+.? '
// UNB+UNOA:3+8773456789012:14+9123456789012:14+140218:1552+MSGNR4711++++++1'
// UNH+1+DESADV:D:96A:UN:EAN005'
// BGM+351+DOCNR4712+9'
// DTM+137:20180218:102'
// DTM+2:20180220:102'
// NAD+SU+9983083940382::9'
// NAD+BY+5332357469542::9'
// NAD+DP+3839204835454::9'
// CPS+1'
// PAC+1++PK'
// PCI+33E'
// GIN+BJ+342603046212321014'
// CPS+2+1'
// PAC+11++CT'
// PCI+33E'
// GIN+BJ+342603046212341547'
// LIN+1++4260304623843:EN'
// QTY+12:110:PCE'
// RFF+ON:8493848394:1'
// CPS+3+1'
// PAC+22++CT'
// PCI+33E'
// GIN+BJ+342603046212378547'
// LIN+2++4260304622123:EN'
// QTY+12:330:PCE'
// RFF+ON:8493848394:2'
// CPS+4+1'
// PAC+45++CT'
// PCI+33E'
// GIN+BJ+342603046212332145'
// LIN+3++4260304624412:EN'
// QTY+12:450:PCE'
// RFF+ON:8493848394:3'
// CNT+2:3'
// UNT+34+1'
// UNZ+1+MSGNR4711'
public class EDIParser {
    Message message;
    UNASegment currentUNA;
    public function init() {
        self.message = new;
        self.currentUNA = new;
    }
    public function parse(string message) {
        self.init();
        string parseText = message;
        string segmentDelimiter = self.getSegmentDelimiter(message);
        string[] segments = regex:split(message, segmentDelimiter);
        self.parseSegments(segments, segmentDelimiter);
    }

    function getSegmentDelimiter(string text) returns string {
        int? unaIndex = text.indexOf(UNA);
        if (unaIndex is int) {
            int segmentDelimiterOffset = unaIndex + UNA.length() + 5;
            return text.substring(segmentDelimiterOffset, segmentDelimiterOffset + 1);
        } else {
            return "'"; // return default
        }
    }

    function parseSegments(string[] segments, string segmentDelimiter) {
        foreach string segment in segments {
            string segmentText = segment;
            UNASegment una;
            UNBSegment unb;
            if segment.startsWith(segmentDelimiter) {
                segmentText = segmentText.substring(1);
            }
            if segmentText.startsWith(UNA) {
                // Parse UNA:+.? 
                self.currentUNA = self.parseUNA(segmentText, segmentDelimiter);
            } else if segmentText.startsWith(UNB) {
                // Parse UNB+UNOA:3+8773456789012:14+9123456789012:14+140218:1552+MSGNR4711++++++1
                unb = self.parseUNB(segmentText);
            }

        // Parse UNH+1+DESADV:D:96A:UN:EAN005
        // Parse BGM+351+DOCNR4712+9
        // Parse DTM+137:20180218:102
        // Parse DTM+2:20180220:102
        // Parse NAD+SU+9983083940382::9
        // Parse NAD+BY+5332357469542::9
        // Parse NAD+DP+3839204835454::9
        // Parse CPS+1
        // Parse PAC+1++PK
        // Parse PCI+33E
        // Parse GIN+BJ+342603046212321014
        // Parse CPS+2+1
        // Parse PAC+11++CT
        // Parse PCI+33E
        // Parse GIN+BJ+342603046212341547
        // Parse LIN+1++4260304623843:EN
        // Parse QTY+12:110:PCE
        // Parse RFF+ON:8493848394:1
        // Parse CPS+3+1
        // Parse PAC+22++CT
        // Parse PCI+33E
        // Parse GIN+BJ+342603046212378547
        // Parse LIN+2++4260304622123:EN
        // Parse QTY+12:330:PCE
        // Parse RFF+ON:8493848394:2
        // Parse CPS+4+1
        // Parse PAC+45++CT
        // Parse PCI+33E
        // Parse GIN+BJ+342603046212332145
        // Parse LIN+3++4260304624412:EN
        // Parse QTY+12:450:PCE
        // Parse RFF+ON:8493848394:3
        // Parse CNT+2:3
        // Parse UNT+34+1
        // Parse UNZ+1+MSGNR4711
        }
    }

    function parseUNA(string text, string segmentDelimiter) returns UNASegment {
        // UNA:+.? 
        int offset = UNA.length();
        string compositeDelimiter = text.substring(offset, offset + 1);
        offset += 1;
        string dataElementDelimeter = text.substring(offset, offset + 1);
        offset += 1;
        string decimalComma = text.substring(offset, offset + 1);
        offset += 1;
        string releaseCharacter = text.substring(offset, offset + 1);
        return new UNASegment
        (compositeDelimiter, dataElementDelimeter, decimalComma, releaseCharacter, segmentDelimiter);
    }

    function parseUNB(string text) returns UNBSegment {
        // UNB+UNOA:3+8773456789012:14+9123456789012:14+140218:1552+MSGNR4711++++++1
        int offset = UNB.length() + 1;
        string charSet = text.substring(offset, offset + 4); // charset is 4 chars
        offset += 5;
        string syntaxVersion = text.substring(offset, offset + 1); // version is 1 chars
        offset += 1;
        int senderTypeIndex = text.indexOf(self.currentUNA.compositeDelimiter, offset + 1) ?: -1;
        string sender = text.substring(offset + 1, senderTypeIndex);
        offset = senderTypeIndex + 1;
        string senderType = text.substring(offset, offset + 2); // version is 1 chars
        offset += 1;
        int recepientTypeIndex = text.indexOf(self.currentUNA.compositeDelimiter, offset + 1) ?: -1;
        string recepient = text.substring(offset, recepientTypeIndex);
        offset = recepientTypeIndex + 1;
        string recepientType = text.substring(offset, offset + 2);
        offset += 3;
        string prepDate = text.substring(offset, offset + 6); // date is 6 chars
        offset += 7;
        string prepTime = text.substring(offset, offset + 4); // time is 4 chars
        offset += 5;
        int interchangeRefIndex = text.indexOf(self.currentUNA.dataElementDelimeter, offset + 1) ?: text.length() - 1;
        string interchangeRef = text.substring(offset, interchangeRefIndex);
        boolean isTest = text.substring(text.length() - 1, text.length()) == "1";
        return new UNBSegment(charSet, syntaxVersion, sender, recepient, prepDate, prepTime, interchangeRef, isTest);
    }
}

class Message {
    UNASegment una;
    UNASegment? unb = ();

    function init() {
        self.una = new UNASegment();
    }

    function getUNA() returns UNASegment {
        return self.una;
    }

    function setUNA(UNASegment una) {
        self.una = una;
    }
}

class UNASegment {
    string compositeDelimiter;
    string dataElementDelimeter;
    string decimalComma;
    string releaseCharacter;
    string segmentDelimiter;

    public function init(string compositeDelimiter = ":", string dataElementDelimeter = "+", string decimalComma = ".", 
                         string releaseCharacter = "?", string segmentDelimiter = "'") {
        self.compositeDelimiter = compositeDelimiter;
        self.dataElementDelimeter = dataElementDelimeter;
        self.decimalComma = decimalComma;
        self.releaseCharacter = releaseCharacter;
        self.segmentDelimiter = segmentDelimiter;
    }
}

class UNBSegment {
    string charSet;
    string syntaxVersion;
    string sender;
    string recepient;
    string prepDate;
    string prepTime;
    string interchangeId;
    boolean isTest;

    public function init(string charSet, string syntaxVersion, string sender, string recepient, string prepDate, 
                         string prepTime, string interchangeId, boolean isTest) {
        self.charSet = charSet;
        self.syntaxVersion = syntaxVersion;
        self.sender = sender;
        self.recepient = recepient;
        self.prepDate = prepDate;
        self.prepTime = prepTime;
        self.interchangeId = interchangeId;
        self.isTest = isTest;
    }
}
