/**
 * Created by user on 8/5/2019.
 */

public with sharing class TestDX {
    public static void getTestDX(){
        System.debug('test DX is successful');
        Account acc = new Account();
        acc.Name = 'vvv';
        acc.Department__c = 'ff';

    }
}