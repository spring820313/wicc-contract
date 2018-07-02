mylib = require "mylib"

--模块功能: 锁仓 v1

--日志类型
LOG_TYPE = 
{
   ENUM_STRING = 0, --字符串类型
   ENUM_NUMBER = 1, --数字类型 
}

--系统账户操作定义
OPER_TYPE = 
{
	ENUM_ADD_FREE = 1,   --系统账户加
	ENUM_MINUS_FREE = 2  --系统账户减
}

--脚本应用账户操作类型定义
APP_OPERATOR_TYPE = 
{ 
	ENUM_ADD_FREE_OP = 1,      --自由账户加
	ENUM_SUB_FREE_OP = 2,      --自由账户减
	ENUM_ADD_FREEZED_OP = 3,   --冻结账户加
	ENUM_SUB_FREEZED_OP = 4    --冻结账户减
}

--账户类型
ADDR_TYPE = 
{
	ENUM_REGID = 1,		-- REG_ID
	ENUM_BASE58 = 2,	-- BASE58 ADDR
}

--交易类型
TX_TYPE = 
{
	TX_CONFIGURE = 1,   --配置
	TX_RECHARGE= 2, 	--充值
	TX_WITHDRAW = 3,	--提现
	TX_CLAIM = 4		--取回
}

--冻结周期(测试用 50个高度)
--FREEZE_PERIOD = 1440 * 6 * 30 * 3	
FREEZE_PERIOD = 50	

--平衡检查 true 打开，false 关闭
gCheckAccount = true 		    

--判断表是否为空
function TableIsEmpty(t)
	return _G.next(t) == nil
end

--判断表非空
function TableIsNotEmpty(t)
    return false == TableIsEmpty(t)
end

--日志输出
function LogPrint(aKey,bLength,cValue)
	assert(bLength >= 1,"LogPrint bLength invlaid")
	if(aKey == LOG_TYPE.ENUM_STRING) then  
      assert(type(cValue) == "string","LogPrint cValue invlaid0")
	elseif(aKey == LOG_TYPE.ENUM_NUMBER)	 then	   
	    assert(TableIsNotEmpty(cValue),"LogPrint cValue invlaid1")
	else
	    error("LogPrint aKey invlaid") 
	end	

	local logTable = {
		key = LOG_TYPE.ENUM_STRING,  
		length = 0,             
		value = nil             
    }
	logTable.key = aKey 
	logTable.length = bLength		
	logTable.value = cValue
	mylib.LogPrint(logTable)
end

--遍历表元素
function Unpack(t,i)
   i = i or 1
   if t[i] then
     return t[i],Unpack(t,i+1)
   end
end

--内存拷贝
function MemCpy(tDest,start0,tSrc,start1,length)
  assert(tDest ~= nil,"tDest is empty")
  assert(TableIsNotEmpty(tSrc),"tDest is empty")
  assert(start0 > 0,"start0 err")
  assert(start1 > 0,"start1 err")
  assert(length > 0,"length err")
  local i 
  for i = 1,length do 
    tDest[start0 + i -1] = tSrc[start1 + i - 1]
  end
end

--比较两表元素是否相同
function MemCmp(tDest,tSrc,start1)
	assert(TableIsNotEmpty(tDest),"tDest is empty")
	assert(TableIsNotEmpty(tSrc),"tSrc is empty")
	local i 
	for i = #tDest, 1, -1 do 
		if tDest[i] > tSrc[i + start1 - 1] then 
			return 1  
		elseif 	tDest[i] < tSrc[i + start1 - 1] then
			return -1 
		else 
		
		end
	end
	return 0 
end

--表元素清零
function ZeroMemory(tbl, start, length)
	for i = start, start + length - 1 do
		tbl[i] = 0
	end
end

--返回table切片 
function Slice(tbl,start,length)
  assert(start > 0,"slice start err")
  assert(length > 0,"slice length err")
  local newTab = {}
  local i
  for i = 0, length - 1 do
	newTab[1 + i] = tbl[start + i]
  end
  return newTab
end

--格式化字符串
function Format(obj, hex)  
    local lua = ""  
    local t = type(obj)
	
    if t == "table" then   
		for i=1, #obj do  
			if hex == false then
				lua = lua .. string.format("%c",obj[i]) 
			else
				lua = lua .. string.format("%02x",obj[i]) 
			end
		end   
    elseif t == "nil" then  
        return nil  
    else  
        error("can not format a " .. t .. " type.")  
    end 

    return lua  
end  

--查询key
function CheckIsConfigKey(key)

	assert(#key > 1,"Key is empty")
	local valueTbl = {mylib.ReadData(key)}
	
	if TableIsNotEmpty(valueTbl) then
		return true, valueTbl
	else
		LogPrint(LOG_TYPE.ENUM_STRING,string.len("Check key empty"),"Check key empty")
		return false, nil
	end
	
	return false, nil
end

--配置
function Configure()
	local adminAddrTbl = {}
	adminAddrTbl = Slice(contract, 3, 34)
	
	local valueTbl = {}
	local isConfig = false
	isConfig,valueTbl = CheckIsConfigKey("config")
	if isConfig then
	  LogPrint(LOG_TYPE.ENUM_STRING,string.len("Already configured"),"Already configured")
	  error("Already configured")
	end
	
	local writeDbTbl = {
      key = "config",  
      length = 34,  
      value = {} 
    } 
  
    writeDbTbl.value = Slice(contract, 3, 34)
  
    if not mylib.WriteData(writeDbTbl) then
      LogPrint(LOG_TYPE.ENUM_STRING, string.len("SaveConfig WriteData error"), "SaveConfig WriteData error")
      error("SaveConfig WriteData error")
    end
end

--充值
function Recharge()
	
	local accountTbl = {0, 0, 0, 0, 0, 0}
	accountTbl = {mylib.GetCurTxAccount()}
	assert(TableIsNotEmpty(accountTbl),"GetCurTxAccount error")
	
	local toAddrTbl = {}
	toAddrTbl = {mylib.GetBase58Addr(Unpack(accountTbl))}
	assert(TableIsNotEmpty(toAddrTbl),"GetBase58Addr error")
	
	local moneyTbl = {}
	moneyTbl = Slice(contract, 3, 8)  
    local money = mylib.ByteToInteger(Unpack(moneyTbl))
	assert(money > 0,"money <= 0")
	
	local payMoneyTbl = {}
	payMoneyTbl = {mylib.GetCurTxPayAmount()}
	assert(TableIsNotEmpty(payMoneyTbl),"GetCurTxPayAmount error")
	local payMoney = mylib.ByteToInteger(Unpack(payMoneyTbl))
	assert(payMoney > 0,"payMoney <= 0")
	
	-- 总金额与充值金额要相等
	assert(money == payMoney, "充值金额不正确1")
	
	local curHeight = 0
    curHeight = mylib.GetCurRunEnvHeight()
	local heightTbl = {}
	heightTbl = {mylib.IntegerToByte4(curHeight)}
	
	local txHash = {mylib.GetCurTxHash()}
	assert(#txHash == 32, "GetCurTxHash err")
	
	local sliceHash = Slice(txHash, 29, 4)
	local strHash = Format(sliceHash, true)
	
	local strAddress = Format(toAddrTbl, false)
	
	local appOperateTbl = {
		operatorType = 0, -- 操作类型
		outHeight = 0,    -- 超时高度
		moneyTbl = {},    
		userIdLen = 0,    -- 地址长度
		userIdTbl = {},   -- 地址
		fundTagLen = 0,   -- fund tag len
		fundTagTbl = {}   -- fund tag 
	} 
	
	appOperateTbl.operatorType = APP_OPERATOR_TYPE.ENUM_ADD_FREEZED_OP
    appOperateTbl.userIdLen = 34
    appOperateTbl.userIdTbl = toAddrTbl
    appOperateTbl.moneyTbl = payMoneyTbl
	appOperateTbl.outHeight = curHeight + FREEZE_PERIOD
	
    assert(mylib.WriteOutAppOperate(appOperateTbl),"WriteOutAppOperate err1")
	
	local freezeHeight = curHeight + FREEZE_PERIOD
	local freezeHeightTbl = {}
	freezeHeightTbl = {mylib.IntegerToByte4(freezeHeight)}
	
	local strHeight = Format(freezeHeightTbl, true)
	local strKey = strAddress .. strHeight .. strHash
	
	local writeDbTbl = {
      key = strKey,  
      length = 16,  
      value = {} 
    }

    MemCpy(writeDbTbl.value, 1, payMoneyTbl, 1, 8)
	MemCpy(writeDbTbl.value, 9, payMoneyTbl, 1, 8)
	
	if not mylib.WriteData(writeDbTbl) then
      LogPrint(LOG_TYPE.ENUM_STRING, string.len("SaveConfig WriteData error"), "SaveConfig WriteData error")
      error("SaveConfig WriteData error")
    end

	return true
end

function WriteWithdrawal(accountType, accTbl, moneyTbl)
	--系统账户结构
	local writeOutputTbl = 
	{
		addrType = accountType,  --账户类型 REG_ID, BASE_58_ADDR
		accountIdTbl = {},  --account id
		operatorType = 0,   --操作类型
		outHeight = 0,      --超时高度
		moneyTbl = {}       --金额
	}	
	--系统账户提现操作
	assert(TableIsNotEmpty(accTbl),"WriteWithDrawal accTbl invlaid1")
	assert(TableIsNotEmpty(moneyTbl),"WriteWithDrawal moneyTbl invlaid1")	
	
	
	writeOutputTbl.addrType = accountType
	writeOutputTbl.operatorType = OPER_TYPE.ENUM_ADD_FREE
	writeOutputTbl.accountIdTbl = {Unpack(accTbl)}
	writeOutputTbl.moneyTbl = {Unpack(moneyTbl)}
	assert(mylib.WriteOutput(writeOutputTbl),"WriteWithDrawal WriteOutput err0")
	
	writeOutputTbl.addrType = ADDR_TYPE.ENUM_REGID
	writeOutputTbl.operatorType = OPER_TYPE.ENUM_MINUS_FREE
	writeOutputTbl.accountIdTbl = {mylib.GetScriptID()}
	assert(mylib.WriteOutput(writeOutputTbl),"WriteWithDrawal WriteOutput err1")
	
	return true
end	

--提现
function Withdraw()
	local accountTbl = {0, 0, 0, 0, 0, 0}
	accountTbl = {mylib.GetCurTxAccount()}
	assert(TableIsNotEmpty(accountTbl),"GetCurTxAccount error")
	
	local idTbl = 
	{
		idLen = 0,       
		idValueTbl = {}	 
	}

	local base58Addr = {}
	base58Addr = {mylib.GetBase58Addr(Unpack(accountTbl))}
	assert(TableIsNotEmpty(base58Addr),"GetBase58Addr error")
	idTbl.idLen = 34
	idTbl.idValueTbl = base58Addr
	
	local freeMoneyTbl = {mylib.GetUserAppAccValue(idTbl)}
	assert(TableIsNotEmpty(freeMoneyTbl),"GetUserAppAccValue error")
	local freeMoney = mylib.ByteToInteger(Unpack(freeMoneyTbl))
  
	assert(freeMoney > 0,"Account balance is 0.")
	
	
	local appOperateTbl = {
		operatorType = 0, -- 操作类型
		outHeight = 0,    -- 超时高度
		moneyTbl = {},    
		userIdLen = 0,    -- 地址长度
		userIdTbl = {},   -- 地址
		fundTagLen = 0,   -- fund tag len
		fundTagTbl = {}   -- fund tag 
	} 
  
    appOperateTbl.operatorType = APP_OPERATOR_TYPE.ENUM_SUB_FREE_OP
    appOperateTbl.userIdLen = idTbl.idLen
    appOperateTbl.userIdTbl = idTbl.idValueTbl
    appOperateTbl.moneyTbl = freeMoneyTbl
  
    assert(mylib.WriteOutAppOperate(appOperateTbl),"WriteOutAppOperate err1")
	
	assert(WriteWithdrawal(ADDR_TYPE.ENUM_REGID, accountTbl, freeMoneyTbl), "WriteWithdrawal err")
	return true
end

--取回
function Claim()
	local accountTbl = {0, 0, 0, 0, 0, 0}
	accountTbl = {mylib.GetCurTxAccount()}
	assert(TableIsNotEmpty(accountTbl),"GetCurTxAccount error")
	
	local base58Addr = {}
	base58Addr = {mylib.GetBase58Addr(Unpack(accountTbl))}
	assert(TableIsNotEmpty(base58Addr),"GetBase58Addr error")
	
	local valueTbl = {}
    local isConfig = false
    isConfig,valueTbl = CheckIsConfigKey("config")
    if not isConfig then
	  LogPrint(LOG_TYPE.ENUM_STRING,string.len("Not configured"),"Not configured")
	  error("Not configured")
    end
	
	local Admin = {}
	Admin = Slice(valueTbl, 1, 34)
	
	if not MemCmp(Admin, base58Addr, 1) == 0 then
	  LogPrint(LOG_TYPE.ENUM_STRING,string.len("Check Admin Account false"),"Check Admin Account false")
	  error("Check Admin Account false")
	end

	local claimAddr = {}
	claimAddr = Slice(contract, 3, 34)

	local claimMoneyTbl = {}
	claimMoneyTbl = Slice(contract, 37, 8)  
    local claimMoney = mylib.ByteToInteger(Unpack(claimMoneyTbl))
	assert(claimMoney > 0, "claimMoney <= 0")

	local heightTbl = Slice(contract, 45, 4)
	local height = mylib.ByteToInteger(Unpack(heightTbl))
	assert(height > 0,"height <= 0")
	
	local txHashTbl = Slice(contract, 49, 64)
	local sliceHash = Slice(txHashTbl, 57, 8)
	
	local strHash = Format(sliceHash, false)
	local strAddress = Format(claimAddr, false)
	local strHeight = Format(heightTbl, true)
	
	local strKey = strAddress .. strHeight .. strHash
	
	valueTbl = {}
	isConfig, valueTbl = CheckIsConfigKey(strKey)
	if not isConfig then
	  LogPrint(LOG_TYPE.ENUM_STRING, string.len("Not configured"), "Not configured")
	  error("Not configured")
	end
	
	local curHeight = 0
    curHeight = mylib.GetCurRunEnvHeight()
	
	if curHeight >= height then
	  LogPrint(LOG_TYPE.ENUM_STRING, string.len("Not enough money"), "Not enough money")
	  error("Not enough money")
	end
	
	local remainMoneyTbl = {}
	remainMoneyTbl = Slice(valueTbl, 9, 8)  
	local remainMoney = mylib.ByteToInteger(Unpack(remainMoneyTbl))
	assert(remainMoney > 0, "remainMoney <= 0")
	
	if claimMoney > remainMoney then 
	  LogPrint(LOG_TYPE.ENUM_STRING, string.len("Not enough money"), "Not enough money")
	  error("Not enough money")
	end
	
	remainMoney = remainMoney - claimMoney

	local appOperateTbl = {
		operatorType = 0, -- 操作类型
		outHeight = 0,    -- 超时高度
		moneyTbl = {},    
		userIdLen = 0,    -- 地址长度
		userIdTbl = {},   -- 地址
		fundTagLen = 0,   -- fund tag len
		fundTagTbl = {}   -- fund tag 
	} 

	appOperateTbl.outHeight = height
	appOperateTbl.operatorType = APP_OPERATOR_TYPE.ENUM_SUB_FREEZED_OP
    appOperateTbl.userIdLen = 34
    appOperateTbl.userIdTbl = claimAddr
    appOperateTbl.moneyTbl = claimMoneyTbl
  
    assert(mylib.WriteOutAppOperate(appOperateTbl),"WriteOutAppOperate err1")
	
	assert(WriteWithdrawal(ADDR_TYPE.ENUM_BASE58, claimAddr, claimMoneyTbl), "WriteWithdrawal err")
	
	local writeDbTbl = {
      key = strKey,  
      length = 16,  
      value = {} 
    }
	
	remainMoneyTbl = {}
	remainMoneyTbl = {mylib.IntegerToByte8(remainMoney)}
	
    MemCpy(writeDbTbl.value, 1, valueTbl, 1, 8)
	MemCpy(writeDbTbl.value, 9, remainMoneyTbl, 1, 8)
	
	if not mylib.ModifyData(writeDbTbl) then
		LogPrint(LOG_TYPE.ENUM_STRING,string.len("Modify info error"),"Modify info error")
		error("Modify info error")
	end
	
	return true
end


function Main()
  --[[
  local i = 1
  
  for i = 1,#contract do
    print("contract")
    print("  ",i,(contract[i]))	
  end
  --]]
  
  assert(#contract >= 2,"contract length err.")
  assert(contract[1] == 0xf2,"Contract identification error.")

  if contract[2] == TX_TYPE.TX_CONFIGURE then
	assert(#contract == 36,"configure contract length err.")
    Configure()
  elseif contract[2] == TX_TYPE.TX_RECHARGE then
    assert(#contract == 10,"recharge contract length err.")
    Recharge()	
  elseif contract[2] ==  TX_TYPE.TX_WITHDRAW then
    assert(#contract == 2,"withdraw contract length err.")
    Withdraw()
  elseif contract[2] ==  TX_TYPE.TX_CLAIM then
    assert(#contract == 112,"claim contract length err.")
    Claim()
  else
    error("RUN_SCRIPT_DATA_ERR")
  end

end

Main()