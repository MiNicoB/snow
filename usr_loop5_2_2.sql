-- not finished
-- plan: create horizontal chain, begining with president and join into two columns 

use <snow_db_name>


drop table if exists ##lpmain
drop table if exists #current_manager
drop table if exists #lpltempuser


create table ##lpmain(
	manager varchar(40)
	,manager_manager varchar(40)
)

create table #current_manager  (
	current_manager varchar(40)
)

insert into #current_manager values('sys_id')-- presisend sys_id

select
	manager
	,sys_id
into
	#lpltempuser
from
	sys_user with (nolock)
where manager is not null

declare @sql_main nvarchar(max);
set @sql_main = 
	'
	insert into ##lpmain
	select
		manager
		,sys_id
	from
		#lpltempuser 
	where
		manager in (select * from #current_manager)

	truncate table  #current_manager
	'

declare @i int = 0
declare @c int = (select count(sys_id) from #lpltempuser)


declare @col nvarchar(max)
declare @new_col nvarchar(max)
declare @sql_current_manager nvarchar(max)
declare @sql_join nvarchar(max)

while (@c > 0)
begin

set @i = @i + 1
	
	if @i = 1
	
	begin
		exec sp_executesql @sql_main
	end
	
	else
		begin
			if @i % 2 = 0
				begin
				
					select 
					top 1 @col = column_name 
					from tempdb.information_schema.columns with (nolock) 
					where table_name like '%##lpmain%' 
					order by ordinal_position desc

				
					set @new_col = 'manager_manager_' + cast(@i as nvarchar(150))

				
					set @sql_current_manager =
					'insert into #current_manager select ' + quotename(@col) + ' from ##lpmain'
					exec sp_executesql @sql_current_manager

				
					set @sql_join =
					'select
						a.*
						,b.sys_id as'+ quotename(@new_col) + 
					'into  ##lpmain_1
					from 
						##lpmain a
					 full join
						(select sys_id, manager from #lpltempuser where manager in (select * from  #current_manager)) b on b.manager = a.' + quotename(@col)

					exec sp_executesql @sql_join
					
					drop table ##lpmain

					delete from #lpltempuser where manager in (select * from #current_manager)

					truncate table #current_manager

					set @c = (select count(sys_id) from #lpltempuser)
				end
			
			else
				begin
				
					select 
					top 1 @col = column_name 
					from tempdb.information_schema.columns with (nolock) 
					where table_name like '%##lpmain_1%' 
					order by ordinal_position desc

				
					set @new_col = 'manager_manager_' + cast(@i as nvarchar(150))

				
					set @sql_current_manager =
					'insert into #current_manager select ' + quotename(@col) + ' from ##lpmain_1'
					exec sp_executesql @sql_current_manager

				
					set @sql_join =
					'select
						a.*
						,b.sys_id as'+ quotename(@new_col) + 
					'into ##lpmain 
					from 
						##lpmain_1 a
					 full join
						(select sys_id, manager from #lpltempuser where manager in (select * from  #current_manager)) b on b.manager = a.' + quotename(@col)

					exec sp_executesql @sql_join
					
					drop table ##lpmain_1
					
					delete from #lpltempuser where manager in (select * from #current_manager)

					truncate table #current_manager

					set @c = (select count(sys_id) from #lpltempuser)
				end 
		end

end
