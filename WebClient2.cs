namespace System.Net
{
#pragma warning disable SYSLIB0014
    public class WebClient2 : WebClient
    {

        public WebClient2()
        {
            this.UploadProgressChanged += (s, e) => {};
            this.DownloadProgressChanged += (s, e) => {};
        }
#pragma warning restore SYSLIB0014

        static WebClient2()
        {
            System.Net.ServicePointManager.ServerCertificateValidationCallback = (_, _, _, _) => true;
        }

        protected override WebRequest GetWebRequest(Uri address)
        {
            var req = (HttpWebRequest)base.GetWebRequest(address);

            req.AutomaticDecompression = DecompressionMethods.GZip | DecompressionMethods.Deflate;

            req.AllowAutoRedirect = this.AllowAutoRedirect;
            req.Timeout = System.Convert.ToInt32(this.Timeout.TotalMilliseconds);
            req.ContinueTimeout = System.Convert.ToInt32(this.Timeout.TotalMilliseconds);
            req.ReadWriteTimeout = System.Convert.ToInt32(this.Timeout.TotalMilliseconds);

            return req;
        }

        protected override void OnUploadProgressChanged(UploadProgressChangedEventArgs e)
        {
            base.OnUploadProgressChanged(e);
            var (message, bytes, (totalSize, unit)) =
                    e.BytesReceived == 0
                        ? ("Uploading", e.BytesSent, this.CalcTotalSize(e.TotalBytesToSend, this.UploadFileSize))
                        : ("Downloading", e.BytesReceived, this.CalcTotalSize(e.TotalBytesToReceive, this.DownloadFileSize));

            Console.Write($"{message}... {MathF.Round((float)bytes / totalSize * 100, 2)}{unit}        {Counter++}        \n");
        }

        protected override void OnDownloadProgressChanged(DownloadProgressChangedEventArgs e)
        {
            base.OnDownloadProgressChanged(e);

            var (totalSize, unit) = this.CalcTotalSize(e.TotalBytesToReceive, this.DownloadFileSize);
            Console.Write($"Downloading... {MathF.Round((float)e.BytesReceived / totalSize * 100, 2)}{unit}        {Counter++}        \n");
        }

        private (long TotalSize, string Unit) CalcTotalSize(long totalBytes, long fallback)
        {
            var totalSize = totalBytes;
            var unit = "%";
            if (totalSize == -1)
            {
                totalSize = fallback;
            }
            if (totalSize < 1)
            {
                totalSize = 100 * 1024 * 1024;
                unit = "MB";
            }
            return (totalSize, unit);
        }

        private long Counter;

        public long DownloadFileSize { get; set; }
        public long UploadFileSize { get; set; }

        private bool _AllowAutoRedirect = true;
        public bool AllowAutoRedirect
        {
            get
            {
                return this._AllowAutoRedirect;
            }
            set
            {
                this._AllowAutoRedirect = value;
            }
        }

        private TimeSpan _Timeout = TimeSpan.FromSeconds((double)30);
        public TimeSpan Timeout
        {
            get
            {
                return this._Timeout;
            }
            set
            {
                this._Timeout = value;
            }
        }
    }
}
