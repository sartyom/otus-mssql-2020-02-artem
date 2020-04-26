// 
// TestConsoleApp
// 

using System;
using SqlLibrary;

namespace ConsoleApp1
{
	class Program
	{
		static void Main( string[] args )
		{
			Console.WriteLine( SqlCurrencyRate.GetCurrencyRate( "USD", "RUB" ) );
		}
	}
}