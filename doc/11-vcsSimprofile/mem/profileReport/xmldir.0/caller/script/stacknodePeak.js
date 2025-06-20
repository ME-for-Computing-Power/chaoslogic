var total = 0;

var stackdata = {
    'aaData': [["<a href='./node1Peak.html' title='test_single_frame'>test_single_frame</a>", "<b href='./node1Peak.html' title='test_single_frame'>test_single_frame</b>",0, 0]
    ],
    'aoColumns': [
        {'sTitle': 'Stack Name', 'bSearchable': false, 'sWidth': '40%'},
        {'sTitle': 'Hiden Name', 'bSearchable': true, 'bVisible': false,'sWidth': '40%'},
        {'sTitle': 'Inclusive Memory', 'bSearchable': false, 'sType': 'simprofile', 'sWidth': '30%'},
        {'sTitle': 'Exclusive Memory', 'bSearchable': false, 'sType': 'simprofile', 'sWidth': '30%'}
    ],
    'sScrollX': '300px',
    'sScrollY': '460px',
    'bPaginate': false,
    'bScrollCollapse': true,
    'aoColumnDefs': [
       {'fnRender': function(oObj, sVal){
           var input = sVal;
           var ret;
           if(input>1024*1024*1024){
               ret = (input/1024/1024/1024).toFixed(1).toString() + ' GB';
           }else if(input>1024*1024){
               ret = (input/1024/1024).toFixed(1).toString() + ' MB';
           }else if(input>1024){
               ret = (input/1024).toFixed(1).toString() + ' KB';
           }else if(input==0){
               return '0';
           }else{
               ret = input.toString() + ' B';
           }
               return ret + ' (' + (input/total*100).toFixed(1).toString()+'%)';
           }, 'aTargets': [ 2, 3 ]
       },
       { 'sClass': 'stackcentre', 'aTargets': [ 2, 3 ]}
    ]
}


jQuery.fn.dataTableExt.oSort['simprofile-asc'] = function(a,b) {
    var va, vb;
    var aa = a.split(' ');
    var ab = b.split(' ');
    if(aa.length<2){
        va = parseFloat(aa[0])
    }else if(aa[1] == "B"){
        va = parseFloat(aa[0])
    }else if(aa[1] == "KB"){
        va = parseFloat(aa[0])*1024
    }else if(aa[1] == "MB"){
        va = parseFloat(aa[0])*1024*1024
    }else if(aa[1] == "GB"){
        va = parseFloat(aa[0])*1024*1024*1024
    }
    if(ab.length<2){
        vb = parseFloat(ab[0])
    }else if(ab[1] == "B"){
        vb = parseFloat(ab[0])
    }else if(ab[1] == "KB"){
        vb = parseFloat(ab[0])*1024
    }else if(ab[1] == "MB"){
        vb = parseFloat(ab[0])*1024*1024
    }else if(ab[1] == "GB"){
        vb = parseFloat(ab[0])*1024*1024*1024
    }
    return ((va < vb) ? -1 : ((va > vb) ? 1 : 0));
}
jQuery.fn.dataTableExt.oSort['simprofile-desc'] = function(a,b) {
    var va, vb;
    var aa = a.split(' ');
    var ab = b.split(' ');
    if(aa.length<2){
        va = parseFloat(aa[0])
    }else if(aa[1] == "B"){
        va = parseFloat(aa[0])
    }else if(aa[1] == "KB"){
        va = parseFloat(aa[0])*1024
    }else if(aa[1] == "MB"){
        va = parseFloat(aa[0])*1024*1024
    }else if(aa[1] == "GB"){
        va = parseFloat(aa[0])*1024*1024*1024
    }
    if(ab.length<2){
        vb = parseFloat(ab[0])
    }else if(ab[1] == "B"){
        vb = parseFloat(ab[0])
    }else if(ab[1] == "KB"){
        vb = parseFloat(ab[0])*1024
    }else if(ab[1] == "MB"){
        vb = parseFloat(ab[0])*1024*1024
    }else if(ab[1] == "GB"){
        vb = parseFloat(ab[0])*1024*1024*1024
    }
    return ((va < vb) ?  1 : ((va > vb) ? -1 : 0));
}
function readData(fileName, begin, end) {
    try {        netscape.security.PrivilegeManager.enablePrivilege('UniversalXPConnect');
        var file = Components.classes['@mozilla.org/file/local;1'].createInstance(Components.interfaces.nsILocalFile);
        file.initWithPath(fileName);
        var lineToRead = end - begin + 1;
        if(lineToRead > 500){
            lineToRead = 500;
        }
        var istream = Components.classes['@mozilla.org/network/file-input-stream;1'].createInstance(Components.interfaces.nsIFileInputStream);
        istream.init(file, 0x01, 00004, 0);
        istream.QueryInterface(Components.interfaces.nsILineInputStream);
        istream.QueryInterface(Components.interfaces.nsISeekableStream);
        var line = {};
        var source = '';
        var lineNo = 0;
        var hasMore = true;
        while(lineToRead > 0 && hasMore){
            hasMore = istream.readLine(line);
            lineNo ++;
            if(lineNo >= begin){
                lineToRead --;
                source = source + line.value + '\n';
            }
        }
    } catch (err) {
        return "";
    }
    return source;
}

function getNameOfLink(str,limit) {
    var spn = $('<span style="visibility:hidden"></span>').text(str).appendTo('body');
    if (parseInt(spn.width()) > parseInt(limit)*0.4) {
        return str.substr(0, 20) + "...";
    } else {
        return str;
    }
}

$(document).ready(function() {
    $('#stacktable').dataTable(stackdata);
    $('.dataTables_scrollHead').width('100%');
    $('.dataTables_scrollBody').width('100%');
    $('.dataTables_scrollHeadInner').width('100%');
    $('.dataTable').width('100%');
    $(window).resize(function() {
         $('.dataTable a').each(function() {
             $(this).text(getNameOfLink($(this).attr('title'), $('.dataTable').width()))
         });
    });
    $('.dataTable a').each(function() {
        $(this).text(getNameOfLink($(this).attr('title'), $('.dataTable').width()))
    });
    if(vlsrc != 'Source Unknown'){
        if(vlsrc.lastIndexOf('-') > vlsrc.lastIndexOf(':')){
            var fileName = vlsrc.substr(0, vlsrc.lastIndexOf(':'));
            var begin = parseInt(vlsrc.substr(vlsrc.lastIndexOf(':')+1, vlsrc.lastIndexOf('-')));
            var end = parseInt(vlsrc.substr(vlsrc.lastIndexOf('-')+1));
        }
    }
});
