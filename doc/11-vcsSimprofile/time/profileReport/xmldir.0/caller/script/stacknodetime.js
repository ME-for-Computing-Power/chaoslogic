var total = 299;

var stackdata = {
    'aaData': [["<a href='./node1Time.html' title='unnamed$$_0'>unnamed$$_0</a>", "<b href='./node1Time.html' title='unnamed$$_0'>unnamed$$_0</b>",37, 6],
        ["<a href='./node2Time.html' title='check_output'>check_output</a>", "<b href='./node2Time.html' title='check_output'>check_output</b>",14, 1],
        ["<a href='./node6Time.html' title='test_rand_frame'>test_rand_frame</a>", "<b href='./node6Time.html' title='test_rand_frame'>test_rand_frame</b>",17, 0],
        ["<a href='./node8Time.html' title='send_frame.unnamed$$_0'>send_frame.unnamed$$...</a>", "<b href='./node8Time.html' title='send_frame.unnamed$$_0'>send_frame.unnamed$$_0</b>",2, 2],
        ["<a href='./node3Time.html' title='check_output.unnamed$$_0'>check_output.unnamed...</a>", "<b href='./node3Time.html' title='check_output.unnamed$$_0'>check_output.unnamed$$_0</b>",13, 4],
        ["<a href='./node7Time.html' title='test_single_frame'>test_single_frame</a>", "<b href='./node7Time.html' title='test_single_frame'>test_single_frame</b>",17, 13],
        ["<a href='./node10Time.html' title='check_serial_output.unnamed$$_0'>check_serial_output....</a>", "<b href='./node10Time.html' title='check_serial_output.unnamed$$_0'>check_serial_output.unnamed$$_0</b>",2, 2],
        ["<a href='./node4Time.html' title='check_serial_output'>check_serial_output</a>", "<b href='./node4Time.html' title='check_serial_output'>check_serial_output</b>",9, 7],
        ["<a href='./node5Time.html' title='send_frame'>send_frame</a>", "<b href='./node5Time.html' title='send_frame'>send_frame</b>",8, 6]
    ],
    'aoColumns': [
        {'sTitle': 'Stack Name', 'bSearchable': false,'sWidth': '40%'},
        {'sTitle': 'Hiden Name', 'bSearchable': true, 'bVisible': false,'sWidth': '40%'},
        {'sTitle': 'Inclusive Time', 'bSearchable': false, 'sType': 'simprofile', 'sWidth': '30%'},
        {'sTitle': 'Exclusive Time', 'bSearchable': false, 'sType': 'simprofile', 'sWidth': '30%'}
    ],
    'sScrollX': '300px',
    'sScrollY': '460px',
    'bPaginate': false,
    'bScrollCollapse': true,
    'aoColumnDefs': [
       {'fnRender': function(oObj, sVal){
           var input = sVal * 1000000 * 2.79 / 299;
           var ret;
           if(input>1000000){
               ret = (input/1000000).toFixed(1).toString() + ' s';
           }else if(input>1000){
               ret = (input/1000).toFixed(1).toString() + ' ms';
           }else if(input==0){
               return '0';
           }else{
               ret = input.toFixed(1).toString() + ' us';
           }
               return ret + ' (' + (sVal/total*100).toFixed(1).toString()+'%)';
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
    }else if(aa[1] == "us"){
        va = parseFloat(aa[0])
    }else if(aa[1] == "ms"){
        va = parseFloat(aa[0])*1000
    }else if(aa[1] == "s"){
        va = parseFloat(aa[0])*1000000
    }
    if(ab.length<2){
        vb = parseFloat(ab[0])
    }else if(ab[1] == "us"){
        vb = parseFloat(ab[0])
    }else if(ab[1] == "ms"){
        vb = parseFloat(ab[0])*1000
    }else if(ab[1] == "s"){
        vb = parseFloat(ab[0])*1000000
    }
    return ((va < vb) ? -1 : ((va > vb) ? 1 : 0));
}
jQuery.fn.dataTableExt.oSort['simprofile-desc'] = function(a,b) {
    var va, vb;
    var aa = a.split(' ');
    var ab = b.split(' ');
    if(aa.length<2){
        va = parseFloat(aa[0])
    }else if(aa[1] == "us"){
        va = parseFloat(aa[0])
    }else if(aa[1] == "ms"){
        va = parseFloat(aa[0])*1000
    }else if(aa[1] == "s"){
        va = parseFloat(aa[0])*1000000
    }
    if(ab.length<2){
        vb = parseFloat(ab[0])
    }else if(ab[1] == "us"){
        vb = parseFloat(ab[0])
    }else if(ab[1] == "ms"){
        vb = parseFloat(ab[0])*1000
    }else if(ab[1] == "s"){
        vb = parseFloat(ab[0])*1000000
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
