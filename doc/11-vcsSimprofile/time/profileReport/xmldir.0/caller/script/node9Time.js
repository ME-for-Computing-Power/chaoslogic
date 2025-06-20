var total = 134;

var callerdata = {
    'aaData': [["<a href='./node8Time.html' title='send_frame'>send_frame</a>", 1, 3, 2, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:106\")'>tb.sv:106</a>"]],
    'aoColumns': [
        {'sTitle': 'Caller Name', 'sClass': 'stackleft', 'sWidth': '24%'},
        {'sTitle': 'Attribute Time', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'Inclusive Time', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'Exclusive Time', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'source', 'sClass': 'stackcentre', 'sWidth': '25%'}
    ],
    'aoColumnDefs': [
        {'fnRender': function(oObj, sVal){
            var input = sVal * 1000000 * 0.94 / 134;
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
    'aaData': [],
    'aoColumns': [
        {'sTitle': 'Callee Name', 'sClass': 'stackleft', 'sWidth': '24%'},
        {'sTitle': 'Attribute Time', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'Inclusive Time', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'Exclusive Time', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'source', 'sClass': 'stackcentre', 'sWidth': '25%'}
    ],
    'aoColumnDefs': [
        {'fnRender': function(oObj, sVal){
            var input = sVal * 1000000 * 0.94 / 134;
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