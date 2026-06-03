using System;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using WallhavenExplorer.Core.Models;
using WallhavenExplorer.Desktop.Services;
using Xunit;

namespace WallhavenExplorer.Tests
{
    public class WallhavenServiceTests
    {
        [Fact]
        public async Task SearchWallpapers_ParsesJsonCorrectly()
        {
            // // AkonDeV 06/2026
            // Arrange
            string mockJson = @"{
                ""data"": [
                    {
                        ""id"": ""y8d1xd"",
                        ""url"": ""https://wallhaven.cc/w/y8d1xd"",
                        ""path"": ""https://w.wallhaven.cc/full/y8/wallhaven-y8d1xd.jpg"",
                        ""resolution"": ""1920x1080"",
                        ""category"": ""general"",
                        ""short_url"": ""https://whvn.cc/y8d1xd"",
                        ""uploader"": {
                            ""username"": ""username1""
                        }
                    }
                ],
                ""meta"": {
                    ""current_page"": 1,
                    ""last_page"": 5
                }
            }";

            var handler = new MockHttpMessageHandler(mockJson);
            var client = new HttpClient(handler)
            {
                BaseAddress = new Uri("https://wallhaven.cc/api/v1/")
            };

            var mockFactory = new MockHttpClientFactory(client);
            var service = new WallhavenService(mockFactory);

            var filters = new SearchFilters { Categories = "111", Purity = "100", Sorting = "relevance" };

            // Act
            var result = await service.SearchWallpapersAsync("anime", filters, 1, CancellationToken.None);

            // Assert
            Assert.NotNull(result);
            var wallpapersList = new System.Collections.Generic.List<Wallpaper>(result.Item1);
            Assert.Single(wallpapersList);
            Assert.Equal(5, result.Item2);
            var wp = wallpapersList[0];
            Assert.Equal("y8d1xd", wp.Id);
            Assert.Equal("username1", wp.Uploader);
        }
    }

    public class MockHttpMessageHandler : HttpMessageHandler
    {
        private readonly string _response;
        public MockHttpMessageHandler(string response)
        {
            _response = response;
        }
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            return Task.FromResult(new HttpResponseMessage
            {
                StatusCode = HttpStatusCode.OK,
                Content = new StringContent(_response)
            });
        }
    }

    public class MockHttpClientFactory : IHttpClientFactory
    {
        private readonly HttpClient _client;
        public MockHttpClientFactory(HttpClient client)
        {
            _client = client;
        }
        public HttpClient CreateClient(string name)
        {
            return _client;
        }
    }
}
