var total = 288;

var callerdata = {
    'aaData': [["<a href='./node1Peak.html' title='test_single_frame'>test_single_frame</a>", 0, 0, 0, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:250\")'>tb.sv:250</a>"],
        ["<a href='./node1Peak.html' title='test_single_frame'>test_single_frame</a>", 0, 0, 0, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:258\")'>tb.sv:258</a>"],
        ["<a href='./node1Peak.html' title='test_single_frame'>test_single_frame</a>", 0, 0, 0, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:261\")'>tb.sv:261</a>"],
        ["<a href='./node1Peak.html' title='test_single_frame'>test_single_frame</a>", 0, 0, 0, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:268\")'>tb.sv:268</a>"],
        ["<a href='./node1Peak.html' title='test_single_frame'>test_single_frame</a>", 0, 0, 0, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:275\")'>tb.sv:275</a>"],
        ["<a href='./node1Peak.html' title='test_single_frame'>test_single_frame</a>", 0, 0, 0, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:281\")'>tb.sv:281</a>"],
        ["<a href='./node1Peak.html' title='test_single_frame'>test_single_frame</a>", 0, 0, 0, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:299\")'>tb.sv:299</a>"],
        ["<a href='./node1Peak.html' title='test_single_frame'>test_single_frame</a>", 0, 0, 0, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:303\")'>tb.sv:303</a>"]],
    'aoColumns': [
        {'sTitle': 'Caller Name', 'sClass': 'stackleft', 'sWidth': '24%'},
        {'sTitle': 'Attribute Memory', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'Inclusive Memory', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'Exclusive Memory', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'source', 'sClass': 'stackcentre', 'sWidth': '25%'}
    ],
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
    'aaData': [["<a href='./node1Peak.html' title='test_single_frame'>test_single_frame</a>", 0, 0, 0, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:250\")'>tb.sv:250</a>"],
        ["<a href='./node1Peak.html' title='test_single_frame'>test_single_frame</a>", 0, 0, 0, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:258\")'>tb.sv:258</a>"],
        ["<a href='./node1Peak.html' title='test_single_frame'>test_single_frame</a>", 0, 0, 0, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:261\")'>tb.sv:261</a>"],
        ["<a href='./node1Peak.html' title='test_single_frame'>test_single_frame</a>", 0, 0, 0, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:268\")'>tb.sv:268</a>"],
        ["<a href='./node1Peak.html' title='test_single_frame'>test_single_frame</a>", 0, 0, 0, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:275\")'>tb.sv:275</a>"],
        ["<a href='./node1Peak.html' title='test_single_frame'>test_single_frame</a>", 0, 0, 0, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:281\")'>tb.sv:281</a>"],
        ["<a href='./node1Peak.html' title='test_single_frame'>test_single_frame</a>", 0, 0, 0, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:299\")'>tb.sv:299</a>"],
        ["<a href='./node1Peak.html' title='test_single_frame'>test_single_frame</a>", 0, 0, 0, "<a href='javascript:void(0)' onclick='var src=new RptCode(\"tb.sv:303\")'>tb.sv:303</a>"]],
    'aoColumns': [
        {'sTitle': 'Callee Name', 'sClass': 'stackleft', 'sWidth': '24%'},
        {'sTitle': 'Attribute Memory', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'Inclusive Memory', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'Exclusive Memory', 'sClass': 'stackright', 'sWidth': '17%'},
        {'sTitle': 'source', 'sClass': 'stackcentre', 'sWidth': '25%'}
    ],
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