var total = 299;

var callerdata = {
    'aaData': [["<a href='./node3Time.html' title='check_output.unnamed$$_0'>check_output.unnamed...</a>", 9, 13, 4, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:378\")'>tb.sv:378</a>"]],
    'aoColumns': [
        {'sTitle': 'Caller Name', 'sClass': 'stackleft', 'sWidth': '24%'},
        {'sTitle': 'Attribute Time', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'Inclusive Time', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'Exclusive Time', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'source', 'sClass': 'stackcentre', 'sWidth': '25%'}
    ],
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
        }, 'aTargets': [ 1, 2, 3]
        }
    ],
    'bInfo': false,
    'bFilter': false,
    'sScrollX': '530px',
    'sScrollY': '140px',
    'bPaginate': false,
    'bScrollCollapse': true
}
var calleedata = {
    'aaData': [["<a href='./node10Time.html' title='check_serial_output.unnamed$$_0'>check_serial_output....</a>", 2, 2, 2, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:146\")'>tb.sv:146</a>"]],
    'aoColumns': [
        {'sTitle': 'Callee Name', 'sClass': 'stackleft', 'sWidth': '24%'},
        {'sTitle': 'Attribute Time', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'Inclusive Time', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'Exclusive Time', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'source', 'sClass': 'stackcentre', 'sWidth': '25%'}
    ],
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
        }, 'aTargets': [ 1, 2, 3]
        }
    ],
    'bInfo': false,
    'bFilter': false,
    'sScrollX': '530px',
    'sScrollY': '140px',
    'bPaginate': false,
    'bScrollCollapse': true
}

$(document).ready(function() {
    $('#callertable').dataTable(callerdata);
    $('#calleetable').dataTable(calleedata);
    $('.dataTables_scrollHeadInner').width('100%');
    $('.dataTable').width('100%');
    prettyPrint();
});