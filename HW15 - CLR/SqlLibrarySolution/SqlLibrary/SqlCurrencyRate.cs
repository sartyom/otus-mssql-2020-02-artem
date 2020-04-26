// 
// SqlLibrary
// 

using System;
using System.Globalization;
using System.Net;
using System.Text.RegularExpressions;

namespace SqlLibrary
{
	public class SqlCurrencyRate
	{
		public static decimal GetCurrencyRate( string fromRate, string toRate )
		{
			var client = new WebClient();

			var rateKey = $"{fromRate}_{toRate}";

			var content = client.DownloadString( $"https://free.currconv.com/api/v7/convert?q={rateKey}&compact=ultra&apiKey=56e104cd163b5fea7194" );

			//подключить newtonsoft json в SQL не получилось, поэтому Regex
			//ошибки для упрощения не обрабатываются!

			var match = Regex.Match( content, "{\"[^\"]+\":(?<RATE>\\d+(.\\d+)?)}" );

			return Decimal.Parse( match.Groups[ "RATE" ].Value, CultureInfo.InvariantCulture );
		}
	}
}